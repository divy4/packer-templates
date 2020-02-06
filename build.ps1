param(
  [Parameter(HelpMessage="What template to build.", Mandatory)]
  [string]$TemplateDirectory
)

$ErrorActionPreference = "Stop"

function Main {
  $TemplateDirectory = $args[0]
  $StartingDir = Get-Location
  try {
    Set-Location $TemplateDirectory
    $PackerArgs = 
      '-var',
      "vm_base_directory=$(Get-VMBaseDirectory)",
      '-var-file=variables.json',
      'template.json'
    packer validate @PackerArgs
    packer build -force @PackerArgs
  } finally {
    Set-Location $StartingDir
  }
}

function Get-VMBaseDirectory {
  $dir = $env:PACKER_VM_DIR
  if ($dir -eq $null) {
    $dir = Get-VBoxVMDirectory
  }
  return $dir
}

function Get-VBoxVMDirectory {
  return $( `
      VBoxManage list systemproperties `
      | Select-String -Pattern '^Default machine folder:' `
    ) -replace '^Default machine folder:\s*', ''
}

Main $TemplateDirectory