# packer-templates

A collection of Packer templates

## File Structure

- common/
- scripts/
      - `SCRIPT-NAME-1`
      - ...
- templates/
  - `TEMPLATE-NAME-1` - The name of the template to build
    - `PROVISIONER`/ - A directory of files used by a provisioner
      - ...
    - template.json - The main template
    - variables.json - All non-secret variables template.json depends on
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

### Provisioner Directory Naming

The provisioners should be named after the `type` value in the corresponding `template.json` and should only contain lowercase letters, numbers, and/or hyphens.
