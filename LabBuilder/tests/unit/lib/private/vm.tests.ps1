$Global:ModuleRoot = Resolve-Path -Path "$($Script:MyInvocation.MyCommand.Path)\..\..\..\..\..\"
$OldPSModulePath = $env:PSModulePath
Push-Location
try
{
    Set-Location -Path $ModuleRoot
    if (Get-Module LabBuilder -All)
    {
        Get-Module LabBuilder -All | Remove-Module
    }

    Import-Module (Join-Path -Path $Global:ModuleRoot -ChildPath 'LabBuilder.psd1') `
        -Force `
        -DisableNameChecking
    $Global:TestConfigPath = Join-Path `
        -Path $Global:ModuleRoot `
        -ChildPath 'Tests\PesterTestConfig'
    $Global:TestConfigOKPath = Join-Path `
        -Path $Global:TestConfigPath `
        -ChildPath 'PesterTestConfig.OK.xml'
    $Global:ArtifactPath = Join-Path `
        -Path $Global:ModuleRoot `
        -ChildPath 'Artifacts'
    $Global:ExpectedContentPath = Join-Path `
        -Path $Global:TestConfigPath `
        -ChildPath 'ExpectedContent'
    $null = New-Item `
        -Path $Global:ArtifactPath `
        -ItemType Directory `
        -Force `
        -ErrorAction SilentlyContinue

    InModuleScope LabBuilder {
    <#
    .SYNOPSIS
    Helper function that just creates an exception record for testing.
    #>
        function GetException
        {
            [CmdLetBinding()]
            param
            (
                [Parameter(Mandatory)]
                [String] $errorId,

                [Parameter(Mandatory)]
                [System.Management.Automation.ErrorCategory] $errorCategory,

                [Parameter(Mandatory)]
                [String] $errorMessage,

                [Switch]
                $terminate
            )

            $exception = New-Object -TypeName System.Exception `
                -ArgumentList $errorMessage
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null
            return $errorRecord
        }
        # Run tests assuming Build 10586 is installed
        $Script:CurrentBuild = 10586


        Describe '\Lib\Private\Vm.ps1\CreateVMInitializationFiles' -Tags 'Incomplete' {
        }


        Describe '\Lib\Private\Vm.ps1\GetUnattendFileContent' -Tags 'Incomplete' {
        }


        Describe '\Lib\Private\Vm.ps1\GetCertificatePsFileContent' -Tags 'Incomplete' {
        }


        Describe '\Lib\Private\Vm.ps1\GetSelfSignedCertificate' -Tags 'Incomplete' {
        }


        Describe '\Lib\Private\Vm.ps1\RecreateSelfSignedCertificate' -Tags 'Incomplete' {
        }


        Describe '\Lib\Private\Vm.ps1\CreateHostSelfSignedCertificate' -Tags 'Incomplete' {
        }


        Describe '\Lib\Private\Vm.ps1\WaitVMInitializationComplete' -Tags 'Incomplete' {
        }


        Describe '\Lib\Private\Vm.ps1\WaitVMStarted' -Tags 'Incomplete'  {
        }


        Describe '\Lib\Private\Vm.ps1\WaitVMOff' -Tags 'Incomplete'  {
        }


        Describe '\Lib\Private\Vm.ps1\GetIntegrationServiceNames' {
            #region Mocks
            Mock Get-CimInstance `
                -ParameterFilter { $Class -eq 'Msvm_VssComponentSettingData' } `
                -MockWith { @{ Caption = 'VSS' }}
            Mock Get-CimInstance `
                -ParameterFilter { $Class -eq 'Msvm_ShutdownComponentSettingData' } `
                -MockWith { @{ Caption = 'Shutdown' }}
            Mock Get-CimInstance `
                -ParameterFilter { $Class -eq 'Msvm_TimeSyncComponentSettingData' } `
                -MockWith { @{ Caption = 'Time Synchronization' }}
            Mock Get-CimInstance `
                -ParameterFilter { $Class -eq 'Msvm_HeartbeatComponentSettingData' } `
                -MockWith { @{ Caption = 'Heartbeat' }}
            Mock Get-CimInstance `
                -ParameterFilter { $Class -eq 'Msvm_GuestServiceInterfaceComponentSettingData' } `
                -MockWith { @{ Caption = 'Guest Service Interface' }}
            Mock Get-CimInstance `
                -ParameterFilter { $Class -eq 'Msvm_KvpExchangeComponentSettingData' } `
                -MockWith { @{ Caption = 'Key-Value Pair Exchange' }}
            #endregion

            Context 'Called' {
                It 'Returns expected Integration Service names' {
                    GetIntegrationServiceNames | Should Be @(
                        'VSS'
                        'Shutdown'
                        'Time Synchronization'
                        'Heartbeat'
                        'Guest Service Interface'
                        'Key-Value Pair Exchange'
                    )
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-CimInstance -Exactly 6
                }
            }
        }


        Describe '\Lib\Private\Vm.ps1\UpdateVMIntegrationServices' {
            # Mock functions
            function Get-VMIntegrationService {}

            #region Mocks
            Mock GetIntegrationServiceNames -MockWith {
                @(
                    'VSS'
                    'Shutdown'
                    'Time Synchronization'
                    'Heartbeat'
                    'Guest Service Interface'
                    'Key-Value Pair Exchange'
                )
            }
            Mock Get-VMIntegrationService -MockWith { @(
                @{ Name = 'Guest Service Interface'; Enabled = $False }
                @{ Name = 'Heartbeat'; Enabled = $True }
                @{ Name = 'Key-Value Pair Exchange'; Enabled = $False }
                @{ Name = 'Shutdown'; Enabled = $True }
                @{ Name = 'Time Synchronization'; Enabled = $True }
                @{ Name = 'VSS'; Enabled = $True }
            ) }
            Function Enable-VMIntegrationService {
                [CmdletBinding()] param ( [Parameter(ValueFromPipeline = $true)] $Name, $VM)
            }
            Mock Enable-VMIntegrationService
            Function Disable-VMIntegrationService {
                [CmdletBinding()] param ( [Parameter(ValueFromPipeline = $true)] $Name, $VM)
            }
            Mock Disable-VMIntegrationService
            #endregion

            $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
            [Array]$Templates = Get-LabVMTemplate -Lab $Lab
            [Array]$Switches = Get-LabSwitch -Lab $Lab

            Context 'Valid configuration is passed with null Integration Services' {
                [Array]$VMs = Get-LabVM -Lab $Lab -VMTemplates $Templates -Switches $Switches
                $VMs[0].IntegrationServices = $null
                It 'Does not throw an Exception' {
                    { UpdateVMIntegrationServices -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMIntegrationService -Exactly 1
                    Assert-MockCalled Enable-VMIntegrationService -Exactly 2
                    Assert-MockCalled Disable-VMIntegrationService -Exactly 0
                }
            }

            Context 'Valid configuration is passed with blank Integration Services' {
                [Array]$VMs = Get-LabVM -Lab $Lab -VMTemplates $Templates -Switches $Switches
                $VMs[0].IntegrationServices = ''
                It 'Does not throw an Exception' {
                    { UpdateVMIntegrationServices -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMIntegrationService -Exactly 1
                    Assert-MockCalled Enable-VMIntegrationService -Exactly 0
                    Assert-MockCalled Disable-VMIntegrationService -Exactly 4
                }
            }

            Context 'Valid configuration is passed with VSS only enabled' {
                [Array]$VMs = Get-LabVM -Lab $Lab -VMTemplates $Templates -Switches $Switches
                $VMs[0].IntegrationServices = 'VSS'
                It 'Does not throw an Exception' {
                    { UpdateVMIntegrationServices -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMIntegrationService -Exactly 1
                    Assert-MockCalled Enable-VMIntegrationService -Exactly 0
                    Assert-MockCalled Disable-VMIntegrationService -Exactly 3
                }
            }
            Context 'Valid configuration is passed with Guest Service Interface only enabled' {
                [Array]$VMs = Get-LabVM -Lab $Lab -VMTemplates $Templates -Switches $Switches
                $VMs[0].IntegrationServices = 'Guest Service Interface'
                It 'Does not throw an Exception' {
                    { UpdateVMIntegrationServices -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMIntegrationService -Exactly 1
                    Assert-MockCalled Enable-VMIntegrationService -Exactly 1
                    Assert-MockCalled Disable-VMIntegrationService -Exactly 4
                }
            }
        }


        Describe '\Lib\Private\Vm.ps1\UpdateVMDataDisks' {
            # Mock functions
            function Get-VM {}
            function Get-VHD {}
            function Resize-VHD {}
            function New-VHD {}
            function Get-VMHardDiskDrive {}
            function Add-VMHardDiskDrive {}
            function Mount-VHD {}
            function Dismount-VHD {}

            #region Mocks
            Mock Get-VM
            Mock Get-VHD
            Mock Resize-VHD
            Mock Move-Item
            Mock Copy-Item
            Mock New-VHD
            Mock Get-VMHardDiskDrive
            Mock Add-VMHardDiskDrive
            Mock Test-Path -ParameterFilter { $Path -eq 'DoesNotExist.Vhdx' } -MockWith { $False }
            Mock Test-Path -ParameterFilter { $Path -eq 'DoesExist.Vhdx' } -MockWith { $True }
            Mock InitializeVHD
            Mock Mount-VHD
            Mock Dismount-VHD
            Mock Copy-Item
            Mock New-Item
            #endregion

            # The same VM will be used for all tests, but a different
            # DataVHds array will be created/assigned for each test.
            $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
            [Array]$Templates = Get-LabVMTemplate -Lab $Lab
            [Array]$Switches = Get-LabSwitch -Lab $Lab
            [Array]$VMs = Get-LabVM -Lab $Lab -VMTemplates $Templates -Switches $Switches

            Context 'Valid configuration is passed with no DataVHDs' {
                $VMs[0].DataVHDs = @()
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a DataVHD that exists but has different type' {
                $DataVHD = [LabDataVHD]::New('DoesExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Fixed
                $DataVHD.Size = 10GB
                $VMs[0].DataVHDs = @( $DataVHD )
                Mock Get-VHD -MockWith { @{
                    VhdType =  'Dynamic'
                } }
                It 'Throws VMDataDiskVHDConvertError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'VMDataDiskVHDConvertError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.VMDataDiskVHDConvertError `
                            -f $VMs[0].Name,$VMs[0].DataVHDs.Vhd,$VMs[0].DataVHDs.VhdType)
                    }
                    $Exception = GetException @ExceptionParameters
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 1
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a DataVHD that exists but has smaller size' {
                $DataVHD = [LabDataVHD]::New('DoesExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Fixed
                $DataVHD.Size = 10GB
                $VMs[0].DataVHDs = @( $DataVHD )
                Mock Get-VHD -MockWith { @{
                    VhdType =  'Fixed'
                    Size = 20GB
                } }
                It 'Throws VMDataDiskVHDShrinkError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'VMDataDiskVHDShrinkError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.VMDataDiskVHDShrinkError `
                            -f $VMs[0].Name,$VMs[0].DataVHDs[0].Vhd,$VMs[0].DataVHDs[0].Size)
                    }
                    $Exception = GetException @ExceptionParameters
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Throw $Exception
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 1
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a DataVHD that exists but has larger size' {
                $DataVHD = [LabDataVHD]::New('DoesExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Fixed
                $DataVHD.Size = 30GB
                $VMs[0].DataVHDs = @( $DataVHD )
                Mock Get-VHD -MockWith { @{
                    VhdType =  'Fixed'
                    Size = 20GB
                } }
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 1
                    Assert-MockCalled Resize-VHD -Exactly 1
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Mock Get-VHD
            Context 'Valid configuration is passed with a SourceVHD and DataVHD that does not exist' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.SourceVhd = 'DoesNotExist.Vhdx'
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Throws VMDataDiskSourceVHDNotFoundError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'VMDataDiskSourceVHDNotFoundError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.VMDataDiskSourceVHDNotFoundError `
                            -f $VMs[0].Name,$VMs[0].DataVHDs[0].SourceVhd)
                    }
                    $Exception = GetException @ExceptionParameters
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Throw $Exception
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a SourceVHD that exists and DataVHD that does not exist' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.SourceVhd = 'DoesExist.Vhdx'
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 1
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a SourceVHD that exists and DataVHD that do not exist and MoveSourceVHD set' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.SourceVhd = 'DoesExist.Vhdx'
                $DataVHD.MoveSourceVHD = $true
                $VMs[0].DataVHDs = @( $DataVHD )

                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 1
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a 10GB Fixed DataVHD that does not exist' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Fixed
                $DataVHD.Size = 10GB
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 1
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a 10GB Dynamic DataVHD that does not exist' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Dynamic
                $DataVHD.Size = 10GB
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 1
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a 10GB Dynamic DataVHD that does not exist and PartitionStyle and FileSystem is set' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Dynamic
                $DataVHD.Size = 10GB
                $DataVHD.PartitionStyle = [LabPartitionStyle]::GPT
                $DataVHD.FileSystem = [LabFileSystem]::NTFS
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 1
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled InitializeVHD -Exactly 1
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 1
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a 10GB Dynamic DataVHD that does not exist and PartitionStyle, FileSystem and CopyFolders is set' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Dynamic
                $DataVHD.Size = 10GB
                $DataVHD.PartitionStyle = [LabPartitionStyle]::GPT
                $DataVHD.FileSystem = [LabFileSystem]::NTFS
                $DataVHD.CopyFolders = "$Global:TestConfigPath\ExpectedContent"
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 1
                    Assert-MockCalled New-VHD -Exactly 1
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled InitializeVHD -Exactly 1
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 1
                    Assert-MockCalled New-Item -Exactly 1
                }
            }
            Context 'Valid configuration is passed with a 10GB Dynamic DataVHD that does not exist and CopyFolders is set' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Dynamic
                $DataVHD.Size = 10GB
                $DataVHD.CopyFolders = "$Global:TestConfigPath\ExpectedContent"
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 1
                    Assert-MockCalled New-VHD -Exactly 1
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled InitializeVHD -Exactly 1
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 1
                    Assert-MockCalled New-Item -Exactly 1
                }
            }
            Context 'Valid configuration is passed with a 10GB Differencing DataVHD that does not exist where ParentVHD is not set' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Differencing
                $DataVHD.Size = 10GB
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Throws VMDataDiskParentVHDMissingError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'VMDataDiskParentVHDMissingError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.VMDataDiskParentVHDMissingError `
                            -f $VMs[0].Name)
                    }
                    $Exception = GetException @ExceptionParameters
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Throw $Exception
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a 10GB Differencing DataVHD that does not exist where ParentVHD does not exist' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Differencing
                $DataVHD.Size = 10GB
                $DataVHD.ParentVHD = 'DoesNotExist.vhdx'
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Throws VMDataDiskParentVHDNotFoundError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'VMDataDiskParentVHDNotFoundError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.VMDataDiskParentVHDNotFoundError `
                            -f $VMs[0].Name,$VMs[0].DataVHDs[0].ParentVhd)
                    }
                    $Exception = GetException @ExceptionParameters
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Throw $Exception
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a 10GB Differencing DataVHD that does not exist' {
                $DataVHD = [LabDataVHD]::New('DoesNotExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Dynamic
                $DataVHD.Size = 10GB
                $DataVHD.ParentVHD = 'DoesExist.vhdx'
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 0
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 1
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
            Mock Get-VHD -MockWith { @{
                VhdType =  'Fixed'
                Size = 10GB
            } }
            Context 'Valid configuration is passed with a 10GB Fixed DataVHD that exists and is already added to VM' {
                Mock Get-VMHardDiskDrive -MockWith { @{ Path = 'DoesExist.vhdx' } }
                $DataVHD = [LabDataVHD]::New('DoesExist.vhdx')
                $DataVHD.VhdType = [LabVHDType]::Fixed
                $DataVHD.Size = 10GB
                $VMs[0].DataVHDs = @( $DataVHD )
                It 'Does not throw an Exception' {
                    { UpdateVMDataDisks -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VHD -Exactly 1
                    Assert-MockCalled Resize-VHD -Exactly 0
                    Assert-MockCalled Move-Item -Exactly 0
                    Assert-MockCalled Copy-Item -Exactly 0
                    Assert-MockCalled New-VHD -Exactly 0
                    Assert-MockCalled Get-VMHardDiskDrive -Exactly 1
                    Assert-MockCalled Add-VMHardDiskDrive -Exactly 0
                    Assert-MockCalled InitializeVHD -Exactly 0
                    Assert-MockCalled Mount-VHD -Exactly 0
                    Assert-MockCalled Dismount-VHD -Exactly 0
                    Assert-MockCalled New-Item -Exactly 0
                }
            }
        }



        Describe '\Lib\Private\Vm.ps1\UpdateVMDVDDrives' {
            # Mock functions
            function Get-VMDVDDrive {}
            function Add-VMDVDDrive {}
            function Set-VMDVDDrive {}

            #region Mocks
            Mock Get-VMDVDDrive
            Mock Add-VMDVDDrive
            Mock Set-VMDVDDrive
            #endregion

            # The same VM will be used for all tests, but a different
            # DVD Drives array will be created/assigned for each test.
            $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
            [Array]$Templates = Get-LabVMTemplate -Lab $Lab
            [Array]$Switches = Get-LabSwitch -Lab $Lab
            [Array]$VMs = Get-LabVM -Lab $Lab -VMTemplates $Templates -Switches $Switches

            Context 'Valid configuration is passed with no DVDDrives' {
                $VMs[0].DVDDrives = @()
                It 'Does not throw an Exception' {
                    { UpdateVMDVDDrives -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMDVDDrive -Exactly 0
                    Assert-MockCalled Add-VMDVDDrive -Exactly 0
                    Assert-MockCalled Set-VMDVDDrive -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a DVD Drive that is empty and empty DVD Drive exists' {
                $DVDDrive = [LabDVDDrive]::New()
                $VMs[0].DVDDrives = @( $DVDDrive )
                Mock Get-VMDVDDrive -MockWith { @{
                    Path = $null
                    ControllerNumber = 0
                    ControllerLocation = 1
                } }
                It 'Does not throw an Exception' {
                    { UpdateVMDVDDrives -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMDVDDrive -Exactly 1
                    Assert-MockCalled Add-VMDVDDrive -Exactly 0
                    Assert-MockCalled Set-VMDVDDrive -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a DVD Drive that is empty and DVD Drive exists but is not empty' {
                $DVDDrive = [LabDVDDrive]::New()
                $VMs[0].DVDDrives = @( $DVDDrive )
                Mock Get-VMDVDDrive -MockWith { @{
                    Path = 'SQL2014_FULL_ENU.iso'
                    ControllerNumber = 0
                    ControllerLocation = 1
                } }
                It 'Does not throw an Exception' {
                    { UpdateVMDVDDrives -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMDVDDrive -Exactly 1
                    Assert-MockCalled Add-VMDVDDrive -Exactly 0
                    Assert-MockCalled Set-VMDVDDrive -Exactly 1
                }
            }
            Context 'Valid configuration is passed with a DVD Drive that has an ISO and DVD Drive exists but is empty' {
                $DVDDrive = [LabDVDDrive]::New()
                $DVDDrive.Path = 'SQL2014_FULL_ENU.iso'
                $VMs[0].DVDDrives = @( $DVDDrive )
                Mock Get-VMDVDDrive -MockWith { @{
                    Path = $null
                    ControllerNumber = 0
                    ControllerLocation = 1
                } }
                It 'Does not throw an Exception' {
                    { UpdateVMDVDDrives -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMDVDDrive -Exactly 1
                    Assert-MockCalled Add-VMDVDDrive -Exactly 0
                    Assert-MockCalled Set-VMDVDDrive -Exactly 1
                }
            }
            Context 'Valid configuration is passed with a DVD Drive that has an ISO and DVD Drive exists but contains a different ISO' {
                $DVDDrive = [LabDVDDrive]::New()
                $DVDDrive.Path = 'SQL2014_FULL_ENU.iso'
                $VMs[0].DVDDrives = @( $DVDDrive )
                Mock Get-VMDVDDrive -MockWith { @{
                    Path = 'SQL2012_FULL_ENU.iso'
                    ControllerNumber = 0
                    ControllerLocation = 1
                } }
                It 'Does not throw an Exception' {
                    { UpdateVMDVDDrives -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMDVDDrive -Exactly 1
                    Assert-MockCalled Add-VMDVDDrive -Exactly 0
                    Assert-MockCalled Set-VMDVDDrive -Exactly 1
                }
            }
            Context 'Valid configuration is passed with a DVD Drive that has an ISO and DVD Drive exists and has the same ISO' {
                $DVDDrive = [LabDVDDrive]::New()
                $DVDDrive.Path = 'SQL2014_FULL_ENU.iso'
                $VMs[0].DVDDrives = @( $DVDDrive )
                Mock Get-VMDVDDrive -MockWith { @{
                    Path = 'SQL2014_FULL_ENU.iso'
                    ControllerNumber = 0
                    ControllerLocation = 1
                } }
                It 'Does not throw an Exception' {
                    { UpdateVMDVDDrives -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMDVDDrive -Exactly 1
                    Assert-MockCalled Add-VMDVDDrive -Exactly 0
                    Assert-MockCalled Set-VMDVDDrive -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a DVD Drive that has an ISO and no DVD Drives exist' {
                $DVDDrive = [LabDVDDrive]::New()
                $DVDDrive.Path = 'SQL2014_FULL_ENU.iso'
                $VMs[0].DVDDrives = @( $DVDDrive )
                Mock Get-VMDVDDrive
                It 'Does not throw an Exception' {
                    { UpdateVMDVDDrives -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMDVDDrive -Exactly 1
                    Assert-MockCalled Add-VMDVDDrive -Exactly 1
                    Assert-MockCalled Set-VMDVDDrive -Exactly 0
                }
            }
            Context 'Valid configuration is passed with a DVD Drive that is empty and no DVD Drives exist' {
                $DVDDrive = [LabDVDDrive]::New()
                $VMs[0].DVDDrives = @( $DVDDrive )
                Mock Get-VMDVDDrive
                It 'Does not throw an Exception' {
                    { UpdateVMDVDDrives -Lab $Lab -VM $VMs[0] } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMDVDDrive -Exactly 1
                    Assert-MockCalled Add-VMDVDDrive -Exactly 1
                    Assert-MockCalled Set-VMDVDDrive -Exactly 0
                }
            }
        }
    }
}
catch
{
    throw $_
}
finally
{
    Pop-Location
    $env:PSModulePath = $OldPSModulePath
}
