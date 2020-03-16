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
    - `VARIANT_NAME_1.json` - Variables for a specific variant of the template
    - ...
  - ...

### Directory Naming

All templates should be named by the following pattern:

```format
PLATFORM_OS_PROVISIONER
```

And all variants should be named by the following pattern:

```format
ROLE.json
```

- PLATFORM = The platform used to host the machine, e.g. `virtualbox`, `vmware`, etc...
- OS = The template operating system (including version if needed), e.g. `windows`, `centos7`, `centos8`, `arch`, etc...
- PROVISIONER = The main provisioner used in the template, e.g. `ansible`, `chef`, `shell`, etc...
- ROLE = The role of the variant, e.g. `development`, `kubernetes_master`, etc...

All template names should be lowercase and only have 2 underscores in it. i.e. remove all non-alphanumeric characters and convert all uppercase letters to lowercase. Variants follow the same rules, except that they can have any number of underscores in their name.

### Builder and Provisioner Directory Naming

The builder and provisioner directories should be named after the `type` value in the corresponding `template.json`, removing all non-alphanumeric, non-hyphen characters and converting to lowercase.
