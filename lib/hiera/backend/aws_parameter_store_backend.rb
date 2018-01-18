class Hiera
  module Backend
    class Aws_parameter_store_backend
      def initialize(cache=nil)
        require 'aws-sdk'
        Hiera.debug("AWS Parameter Store backend starting")

        @cache = read_parameters_from_aws_parameter_store()
        Hiera.debug("Cache=#{@cache}")
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up #{key} in AWS Parameter Store backend")
        if @cache.include?(key)
          # Extra logging that we found the key. This can be outputted
          # multiple times if the resolution type is array or hash but that
          # should be expected as the logging will then tell the user ALL the
          # places where the key is found.
          Hiera.debug("Found #{key}")

          # for array resolution we just append to the array whatever
          # we find, we then goes onto the next file and keep adding to
          # the array
          #
          # for priority searches we break after the first found data item
          new_answer = Backend.parse_answer(@cache[key], scope)
          case resolution_type
          when :array
            raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer,answer)
          else
            answer = new_answer
          end
        end

        return answer
      end

      private

      def read_parameters_from_aws_parameter_store()
        Hiera.debug("Creating AWS client")
        client = Aws::SSM::Client.new()

        prefix = Config[:aws_parameter_store][:prefix]
        max_results = Config[:aws_parameter_store][:max_results] || 50

        Hiera.debug("Obtaining parameters from AWS Parameter Store with prefix #{prefix}")
        parameters = {}
        next_token = nil
        loop do
          resp = client.describe_parameters({
            filters: [
              {
                key: "Name",
                values: [ prefix ],
              },
            ],
            max_results: max_results,
            next_token: next_token
            })
          resp.parameters.each do |parameter|
            Hiera.debug("Found paramenter: #{parameter}")
            presp = client.get_parameter({
              name: parameter.name,
              with_decryption: true,
            })
            Aws_parameter_store_backend.add_parameter_to_hash(parameter.name[prefix.length..-1], presp.parameter.value, parameters)
          end
          next_token = resp.next_token
          break unless next_token
        end
        parameters
      end

      def self.add_parameter_to_hash(name, value, hash)
        def self.add_parameter_to_hash_helper(name_list, value, current_hash)
          raise "Can not add value if name is empty or invalid" if name_list.empty?
          head = name_list.shift
          if name_list.empty?
            raise "Element already exists" if current_hash.has_key?(head)
            current_hash[head]=value
            return
          end
          current_hash[head] = {} unless current_hash.has_key?(head)
          new_hash = current_hash[head]
          raise "Parent element already exists" unless new_hash.is_a?(Hash)
          add_parameter_to_hash_helper(name_list, value, current_hash[head])
        end
        add_parameter_to_hash_helper(name.split('.'), value, hash)
      end
    end
  end
end
