# ansible

This is my personal Ansible repo, which defines a large amount of my IaC.

## Structure

This repo follows the [Ansible best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#directory-layout)
for it's layout, as well as the entire best practices guide in general
(or at least I try).

## Best Practices and Decisions I've Made that I Might Forget in the Future

### Role Dependencies

No role can be dependent on another role by any code-based means.
i.e. they are allowed to be dependent on the artifacts other roles produce
(e.g. almost all deployment roles have a dependency that the hostname has been
set by the `common_deploy` role), but they cannot be dependent on each other
in terms of code (e.g. variables). This is to prevent, or at least reduce,
roles from getting tangled together over time.

### Setup vs Deploy Roles

Almost every role is split up into 2 separate roles: a `_setup` and a `_deploy`
role. This distinction between setup and deploy roles is made to make
role templates possible (i.e. my
[packer-templates](https://github.com/divy4/packer-templates) project).
Deploy roles contain actions that do at least one of the following:

- produce artifacts that are...
  - host sensitive (e.g. the hostname)
  - security sensitive (e.g. ssh keys)
  - highly time-sensitive (e.g. installing _the latest_ updates
    since building a template)
- must be executed multiple times over the lifespan of a host
  (e.g. updating the time on a machine that doesn't have ntp enabled)
- depend on actions that meet at least one of the above criteria

As you can probably guess by now, setup roles contain actions that do not
qualify to be in deploy roles. Note that installing updates should be part of
setup roles, as deploy roles are only concerned with deploying what is
_currently_ installed by it's setup role.

### Variable Layout and Precedence

Remember [Chef attributes](https://docs.chef.io/attributes/)?
You know, how there are 6 different levels of variables that can be defined in
at least 7 different locations, with 4 different possible blacklists and 4
different whitelists for a theoretical list of 6*7+4+4=50 different locations
a single attribute could be modified. But wait, attribute and recipe files
can define attributes, which are made of whatever ruby code you want.
So thanks to theory of computation, there are an _infinite_ number of ways a
variable can be defined! I don't want that garbage here.

So yes, I know functions like
[combine](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html#combining-hashes-dictionaries)
can be used to merge variables manually or even extensions like
[ansible-merge-vars](https://pypi.org/project/ansible-merge-vars/)
that can be used to merge them automatically. But that's a lot of effort and
simply assigning a suffix to every group of variables that indicates at what
location that variable was assigned makes it very easy to figure out where
a variable was defined.

So for the purposes of this repo, I've decided to go with the following
convention:

- All variables defined outside of runtime must belong inside a root-level
variable named after the role it belongs to and where it was defined
- Root-level variables will be named `ROLE_SUFFIX` where `ROLE` is
  the exact same name as the role and `SUFFIX` is one of the following
  - `group` - Defined in `group_vars/*.yml`
  - `hosts` - Defined in `host_vars/*.yml`
  - `play` - Defined in playbook file
  - `role` - Defined in `roles/*/defaults/main.yml`
- No 2 roles can share _any_ variables, even between setup and deploy roles
- The `combine` function or similar tools are never to be used to merge
  variables, unless merging two or more objects is necessary for the desired
  functionality
  - This means, even if it exists in 1 of every environment, any variable
    with environmental differences must be migrated out of the `ROLE_role` or
    `ROLE_play` root-level variable into a group or hosts root-level variable.
