# packer-templates

A collection of Packer templates

## Repo File Structure

- provisioners/
  - `PROVISIONER-NAME-1`/ - A directory of common files for a provisioner
    - ...
  - ...
- output/ - The default output directory (ignored by git)
- templates/
  - `TEMPLATE-NAME-1` - The name of the template to build
    - `PROVISIONER`/ - A directory of template-specific files used by a specific provisioner
      - ...
    - template.json - The template
    - variables.json - Template-specific variables
  - ...

### Template Directory Naming

All templates should be named by the following pattern:

```format
TECHNOLOGY-OS-OSVERSION
```

- TECHNOLOGY = The technology this template supports, e.g. `rabbitmq`, `docker`, etc...
- OS = The template operating system, e.g. `windows`, `centos`, `ubuntu`, `arch`, etc...
- OSVERSION = The version of the operating system, e.g. `2019`, `8`, `18.04`, `latest`, etc...

All template names should be lowercase and only have 2 hyphens in it. i.e. remove all non-alphanumeric characters and convert all uppercase letters to lowercase.

### Builder and Provisioner Directory Naming

The builder and provisioner directories should be named after the `type` value in the corresponding `template.json`, removing all non-alphanumeric, non-hyphen characters and converting to lowercase.
