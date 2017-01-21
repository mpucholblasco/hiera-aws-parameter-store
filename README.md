Introduction
============

Hiera is a configuration data store with pluggable back ends,
hiera-aws-parameter-store is a back-end that fetches configuration values
from [AWS Parameter Store](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/systems-manager-paramstore.html).


Installation
============

TODO

Dependencies
============

Hiera-aws-parameter-store specifies a gem dependency for the aws-sdk.

Configuration
=============

hiera-aws-parameter-store configuration is quite simple. It uses default
[AWS connection](http://docs.aws.amazon.com/sdkforruby/api/#Configuration) and
the following parameters:
* prefix : prefix used to find parameters in AWS Parameter Store. Mandatory.
* max_results : maximum number of results per AWS Parameter Store request. Default
value is 50 (which is the maximum at 2017-01-21).

Here is a sample `hiera.yaml`:

<pre>
---
:backends:
    - aws_parameter_store

:aws_parameter_store:
    :prefix: puppet.
    :max_results: 50

:logger: console
</pre>

AWS credentials
===============
You need AWS credentials in order to access to AWS Parameter Store.

The following policy shows you the required permissions:
<pre>
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:{region}:{account}:parameter/{prefix}*"
        }
    ]
}
</pre>
where:
* region: AWS region in which parameters are stored.
* account: your AWS account.
* prefix: prefix for those parameters you want to access from Hiera. E.g. if you
want to organize your parameters starting with `puppet.`, you have to use this
as prefix. As an example, you can have parameters like: `puppet.myapp.version`.

Conversions between AWS Parameter Store and Hiera types
=======================================================
In AWS Parameter Store are present the following types:
* String: if the parameter name does not contains dots (`.`), the resulting hiera
object is a String with parameter's value. If it contains dots, it's splitted and
converted into a hash of objects with the last element as a string.
* String List: Converted into an array.
* Secure String: Not compatible yet.

Examples:
<pre>
# Strings
myappname=MyAppName  (String) -> hiera('myappname') = "MyAppName" (String)
myapp.name=MyAppName (String)
myapp.version=1.3    (String) -> hiera_hash('myapp') = {"name"=>"MyAppName","version"=>"1.3"} (Hash)

# String lists
mylist=e1,e2,e3      (String List) -> hiera('mylist') = ["e1","e2","e3"]
myapp.name=MyAppName (String)
myapp.list=1,2,3     (String List) -> hiera_hash('myapp') = {"name"=>"MyAppName","list"=>["1","2","3"]}
</pre>

Todo
====

- Add support for secure strings.
