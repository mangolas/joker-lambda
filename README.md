Minimal AWS Lambda runtime using [Joker](https://github.com/candid82/joker).

Quick usage help (depends on AWS cli):

```shell script
$ export AWS_PROFILE=xxx AWS_DEFAULT_REGION=xxx
$ LAMBDA_ROLE=<valid iam role arn> make create
$ aws lambda invoke --function-name hello-world target/output; cat target/output
# Make changes to handler
$ make update
```
