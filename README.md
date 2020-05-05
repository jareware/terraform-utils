# Terraform Utils

This repository contains reusable [Terraform](https://www.terraform.io/) utility modules, which are liberally licensed, and can be shared between projects.

## Design decisions

1. Each module should be thoroughly documented with a README - no source code dumps
1. Each module should have easy to use examples - for delicious copy-pasta
1. Modules need not offer infinite flexibility, but do one thing well - users can always make their own module using ours as a baseline

## Naming conventions

### Short version

For each module in this repository, you can either:

- Provide a `name_prefix` as input, and all resources created by that module will have names starting with that prefix, or
- Not provide `name_prefix`, and all resource names will have a unique, generated prefix, guaranteed to not conflict with other resource names

### Longer version

When creating resources on AWS, it's common to follow a hierarchical naming convention such as the following:

1. All resources related to your app have names starting with `my-app`
1. Then the environment (e.g. `dev` or `prod`)
1. Then the component/tier (e.g. `frontend` or `backend`)
1. Then a possible sub-component (e.g. `api` or `worker` for backend)
1. Then a possible name for the individual resource (e.g. `logs` or `content`)

If you model your Terraform module structure in the same fashion, you might end up with something like this:

```
my-app
├── dev
│   ├── backend
│   │   ├── api
│   │   └── worker
│   │       └── logs
│   └── frontend
│       └── content
└── prod
    ├── backend
    │   ├── api
    │   └── worker
    │       └── logs
    └── frontend
        └── content
```

And thus resource names like:

```
my-app-dev-backend
my-app-dev-backend-api
my-app-dev-backend-worker
my-app-dev-backend-worker-logs
my-app-dev-frontend
my-app-dev-frontend-content
my-app-prod-backend
my-app-prod-backend-api
my-app-prod-backend-worker
my-app-prod-backend-worker-logs
my-app-prod-frontend
my-app-prod-frontend-content
```

An elegant way to implement this is to have each module take an input called `name_prefix`, and pass it along to its child modules. That is:

1. In your root module, set `name_prefix` to a default value:
   ```
   variable "name_prefix" {
     default = "my-app"
   }
   ```
1. When you instantiate your main module for different environments, you pass along `name_prefix` with the appropriate suffix:

   ```
   module "dev" {
     name_prefix = "${var.name_prefix}-dev"
   }

   module "prod" {
     name_prefix = "${var.name_prefix}-prod"
   }
   ```

1. Within that module, when you instantiate modules for backend & frontend, you again pass along `name_prefix`:
   ```
   module "backend" {
     name_prefix = "${var.name_prefix}-backend"
   }
   ```
1. And so on, for each level of the module hierarchy
1. On any level, when creating resources, you do so using the same prefix, for example creating an S3 bucket:
   ```
   resource "aws_s3_bucket" "content" {
     bucket = "${var.name_prefix}-content"
   }
   ```

Thus, each module gets a dedicated namespace that's:

- guaranteed to not conflict with resources from other modules
- not tied to the top level namespace, facilitating reuse
- easy to identify on the AWS web console as belonging to a specific env/component/etc
- convenient for use with IAM permissions (e.g. granting dev env backend access to `my-app-dev-backend-*`, thus excluding the frontend component, and the production environment entirely)

**All modules within this repository follow this convention**, taking a `name_prefix`, and passing it along to their child modules (if any).

If you don't want to follow this convention, you can simply omit the `name_prefix` input. In that case, a unique name prefix is generated automatically (`"aws-static-site-2rdc7iqm"` for the `aws_static_site` module, for example), thus ensuring your resource names won't clash with those of others.

## Caveats

- At the time of writing, [support for the `profile` property of the AWS provider is still... wonky](https://github.com/terraform-providers/terraform-provider-aws/issues/233), especially in cases where the provider needs to be aliased. Configuring your AWS provider via the standard `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables is recommended wholeheartedly.

## Versioning policy

1. New versions are released often, so users can pin their modules (using `master` as a `source` for Terraform modules is a terrible idea)
1. Bump major version when either new modules are released, or existing modules get backwards-incompatible changes
1. Bump minor version otherwise

## Additional resources

In addition to the modules here, there's a lot of useful ones in the wild. For example:

- https://registry.terraform.io/ - lots of solutions to common problems, some verified by Hashicorp themselves
- https://github.com/cloudposse - look for repos starting with `terraform-` for lots of good building blocks

## Release process

Please use the included release script. For example:

```
$ ./release.sh
Checking dependencies... OK
Running terraform fmt... OK
Checking for clean working copy... OK
Parsing git remote... OK
Verifying GitHub API access... OK
Fetching previous tags from GitHub... OK

Previous release was: v9.1
This release will be: v9.2

Tagging new release... OK
Pushing release to GitHub... OK
Creating release on GitHub... OK
Updating example code with new release... OK
Updating Terraform module docs... OK
Creating commit from docs updates... OK
Pushing updated docs to GitHub... OK
Cleaning up... OK

New release is: https://github.com/futurice/terraform-utils/releases/tag/v9.2

```

## License

MIT
