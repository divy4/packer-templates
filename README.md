# packer-templates

A collection of Packer templates

## Template Types

This repo contains 2 different types of templates, OS templates and provisioner templates.

### OS Templates

OS templates are templates that install a specific OS and perform a few basic setup steps via an ISO or similar builder (e.g. `virtualbox-iso`). These templates are often very unique and using a separate template for each OS-version pair (i.e. only 1 role per template) is recommended unless merging the templates for 2 different versions of the same OS is easy.

### Provisioner Templates

Provisioner templates are templates that build on top of other OS or provisioner templates via a meta builder (e.g. `virtualbox-ova`). These templates are often very simple, only requiring 1 or 2 provisioners along with some simple hardware modifications (e.g. cpu count and memory size), and can easily have multiple roles within it.

## Repo File Structure

- provisioners/
  - `PROVISIONER_NAME_1`/ - A directory of common files for a provisioner
    - ...
  - ...
- `output/` - The default output directory (ignored by git)
- `templates/`
  - `TEMPLATE_NAME_1/` - A template of a generic machine architecture
    - `template.json` - The template
    - `ROLE_NAME_1.json` - Variables for a specific role
    - ...
  - ...

### Directory Naming

All templates should be named by 1 of the following 2 patterns:

```format
OS[_VERSION]
```

```format
PROVISIONER[_VARIANT]
```

The first of these patterns is for OS templates whereas the second is for provisioner templates.

And all roles within a template should be named by the following pattern:

```format
ROLE.json
```

- OS = The template operating system, e.g. `windows`, `centos`, or `arch`.
- VERSION = The version of the OS being installed, e.g. `2016` or `7`. This is not required for OS's that don't have a version (i.e. Arch Linux).
- PROVISIONER = The main provisioner used in the template, e.g. `ansible`, `chef`, or `shell`.
- VARIANT = An optional (but optimally sparse) component of a template name when the basic template can't accommodate a specific role. E.g. additional hardware.
- ROLE = The role of the specific instance of the template, e.g. `development`, `kubernetes_master`, etc...
  - For OS templates that contain 1 role, the name should be `base`.
  - For OS templates that contain a role for each OS version, the name should be the version of the OS, e.g. `7` and `8` for a `centos` template.

All template names should be lowercase. i.e. remove all non-alphanumeric characters and convert all uppercase letters to lowercase. Underscores should be used to join multiple words instead of hyphens.

### Builder and Provisioner Directory Naming

The builder and provisioner directories should be named after the `type` value in the corresponding `template.json`, removing all non-alphanumeric, non-hyphen characters and converting to lowercase.
