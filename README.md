# packer-templates

A collection of Packer templates

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

All templates should be named by the following pattern:

```format
PLATFORM_OS_PROVISIONER[_VARIANT]
```

And all variants should be named by the following pattern:

```format
ROLE.json
```

- PLATFORM = The platform used to host the machine, e.g. `virtualbox`, `vmware`, etc...
- OS = The template operating system (including version if needed), e.g. `windows`, `centos7`, `centos8`, `arch`, etc...
- PROVISIONER = The main provisioner used in the template, e.g. `ansible`, `chef`, `shell`, etc...
- VARIANT = An optional (but optimally sparse) component of a template name when the basic template can't accommodate a specific base image. E.g. additional hardware.
- ROLE = The role of the specific instance of the template, e.g. `development`, `kubernetes_master`, etc...

All template names should be lowercase and only have 2 or 3 underscores in it. i.e. remove all non-alphanumeric characters and convert all uppercase letters to lowercase. Variants follow the same rules, except that they can have any number of underscores in their name.

### Builder and Provisioner Directory Naming

The builder and provisioner directories should be named after the `type` value in the corresponding `template.json`, removing all non-alphanumeric, non-hyphen characters and converting to lowercase.
