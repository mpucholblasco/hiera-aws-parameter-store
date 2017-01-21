require 'spec_helper'
require 'hiera/backend/aws_parameter_store_backend'

describe Hiera::Backend::Aws_parameter_store_backend do
  describe "#add_parameter_to_hash" do
    it "when name is empty" do
      hash = {}
      parameter_name = ''
      parameter_value = 'value'
      expect {
        Hiera::Backend::Aws_parameter_store_backend.send(:add_parameter_to_hash, parameter_name, parameter_value, hash)
      }.to raise_error(RuntimeError)
    end

    it "when name is direct string" do
      hash = {}
      parameter_name = 'name'
      parameter_value = 'value'
      Hiera::Backend::Aws_parameter_store_backend.send(:add_parameter_to_hash, parameter_name, parameter_value, hash)
      expect(hash).to include(
        parameter_name => parameter_value
      )
    end

    it "when name contains one dot" do
      hash = {}
      parameter_name = 'first.name'
      parameter_value = 'value'
      Hiera::Backend::Aws_parameter_store_backend.send(:add_parameter_to_hash, parameter_name, parameter_value, hash)
      expect(hash).to include(
        "first" => {
          "name" => parameter_value
        }
      )
    end

    it "when name contains one dot but hash contains the first element" do
      hash = { "first" => "first_value" }
      parameter_name = 'first.name'
      parameter_value = 'value'
      expect {
        Hiera::Backend::Aws_parameter_store_backend.send(:add_parameter_to_hash, parameter_name, parameter_value, hash)
      }.to raise_error(RuntimeError)
    end
  end
end
