$Global:ModuleRoot = Resolve-Path -Path "$($Script:MyInvocation.MyCommand.Path)\..\..\..\..\..\"

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


        Describe 'Get-LabSwitch' {

            Context 'Configuration passed with switch missing Switch Name.' {
                It 'Throws a SwitchNameIsEmptyError Exception' {
                    $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
                    $Lab.labbuilderconfig.switches.switch[0].RemoveAttribute('name')
                    $ExceptionParameters = @{
                        errorId = 'SwitchNameIsEmptyError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.SwitchNameIsEmptyError)
                    }
                    $Exception = GetException @ExceptionParameters

                    { Get-LabSwitch -Lab $Lab } | Should Throw $Exception
                }
            }
            Context 'Configuration passed with switch missing Switch Type.' {
                It 'Throws a UnknownSwitchTypeError Exception' {
                    $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
                    $Lab.labbuilderconfig.switches.switch[0].RemoveAttribute('type')
                    $ExceptionParameters = @{
                        errorId = 'UnknownSwitchTypeError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.UnknownSwitchTypeError `
                            -f '','External')
                    }
                    $Exception = GetException @ExceptionParameters

                    { Get-LabSwitch -Lab $Lab } | Should Throw $Exception
                }
            }
            Context 'Configuration passed with switch invalid Switch Type.' {
                It 'Throws a UnknownSwitchTypeError Exception' {
                    $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
                    $Lab.labbuilderconfig.switches.switch[0].type='BadType'
                    $ExceptionParameters = @{
                        errorId = 'UnknownSwitchTypeError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.UnknownSwitchTypeError `
                            -f 'BadType','External')
                    }
                    $Exception = GetException @ExceptionParameters

                    { Get-LabSwitch -Lab $Lab } | Should Throw $Exception
                }
            }
            Context 'Configuration passed with switch containing adapters but is not External type.' {
                $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
                $Lab.labbuilderconfig.switches.switch[0].type='Private'
                It 'Throws a AdapterSpecifiedError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'AdapterSpecifiedError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.AdapterSpecifiedError `
                            -f 'Private',"$($Lab.labbuilderconfig.settings.labid) External")
                    }
                    $Exception = GetException @ExceptionParameters

                    { Get-LabSwitch -Lab $Lab } | Should Throw $Exception
                }
            }
            Context 'Valid configuration is passed with and Name filter set to matching switch' {
                It 'Returns a Single Switch object' {
                    $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
                    [Array] $Switches = Get-LabSwitch -Lab $Lab -Name $Lab.labbuilderconfig.switches.switch[0].name
                    $Switches.Count | Should Be 1
                }
            }
            Context 'Valid configuration is passed with and Name filter set to non-matching switch' {
                It 'Returns a Single Switch object' {
                    $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
                    [Array] $Switches = Get-LabSwitch -Lab $Lab -Name 'Does Not Exist'
                    $Switches.Count | Should Be 0
                }
            }
            Context 'Valid configuration is passed' {
                It 'Returns Switches Object that matches Expected Object' {
                    $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
                    [Array] $Switches = Get-LabSwitch -Lab $Lab
                    Set-Content -Path "$Global:ArtifactPath\ExpectedSwitches.json" -Value ($Switches | ConvertTo-Json -Depth 4)
                    $ExpectedSwitches = Get-Content -Path "$Global:ExpectedContentPath\ExpectedSwitches.json"
                    [String]::Compare((Get-Content -Path "$Global:ArtifactPath\ExpectedSwitches.json"),$ExpectedSwitches,$true) | Should Be 0
                }
            }
        }



        Describe 'Initialize-LabSwitch' {

            $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
            [LabSwitch[]] $Switches = Get-LabSwitch -Lab $Lab

            Mock Get-VMSwitch -MockWith {
                @{
                    Name = 'Dummy Switch'
                    SwitchType = 'External'
                }
            }
            Mock New-VMSwitch
            Mock Get-VMNetworkAdapter
            Mock Add-VMNetworkAdapter
            Mock Set-VMNetworkAdapterVlan
            Mock Get-NetAdapter -MockWith {
                @{
                    Name       = 'Ethernet'
                    MACAddress = '0012345679A0'
                    Status     = 'Up'
                    Virtual    = $False
                }
            }

            Context 'Valid configuration is passed' {
                It 'Does not throw an Exception' {
                    { Initialize-LabSwitch -Lab $Lab -Switches $Switches } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMSwitch -Exactly 6
                    Assert-MockCalled New-VMSwitch -Exactly 5
                    Assert-MockCalled Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled Add-VMNetworkAdapter -Exactly 4
                    Assert-MockCalled Set-VMNetworkAdapterVlan -Exactly 0
                    Assert-MockCalled Get-NetAdapter -Exactly 2
                }
            }

            Context 'Valid configuration without switches is passed' {
                It 'Does not throw an Exception' {
                    { Initialize-LabSwitch -Lab $Lab } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMSwitch -Exactly 6
                    Assert-MockCalled New-VMSwitch -Exactly 5
                    Assert-MockCalled Get-VMNetworkAdapter -Exactly 1
                    Assert-MockCalled Add-VMNetworkAdapter -Exactly 4
                    Assert-MockCalled Set-VMNetworkAdapterVlan -Exactly 0
                    Assert-MockCalled Get-NetAdapter -Exactly 2
                }
            }

            Context 'Valid configuration NAT with blank NAT Subnet Address' {
                $Switches[0].Type = [LabSwitchType]::NAT
                It 'Throws a NatSubnetAddressEmptyError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'NatSubnetAddressEmptyError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.NatSubnetAddressEmptyError `
                            -f $Switches[0].Name)
                    }
                    $Exception = GetException @ExceptionParameters

                    { Initialize-LabSwitch -Lab $Lab -Switches $Switches } | Should Throw $Exception
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMSwitch -Exactly 1
                    Assert-MockCalled New-VMSwitch -Exactly 0
                    Assert-MockCalled Get-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled Add-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled Set-VMNetworkAdapterVlan -Exactly 0
                    Assert-MockCalled Get-NetAdapter -Exactly 0
                }
            }

            Context 'Valid configuration with blank switch name passed' {
                $Switches[0].Type = [LabSwitchType]::External
                $Switches[0].Name = ''
                It 'Throws a SwitchNameIsEmptyError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'SwitchNameIsEmptyError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.SwitchNameIsEmptyError)
                    }
                    $Exception = GetException @ExceptionParameters

                    { Initialize-LabSwitch -Lab $Lab -Switches $Switches } | Should Throw $Exception
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMSwitch -Exactly 1
                    Assert-MockCalled New-VMSwitch -Exactly 0
                    Assert-MockCalled Get-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled Add-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled Set-VMNetworkAdapterVlan -Exactly 0
                    Assert-MockCalled Get-NetAdapter -Exactly 0
                }
            }

            [LabSwitch[]] $Switches = Get-LabSwitch -Lab $Lab

            Context 'Valid configuration with External switch with binding Adapter name bad' {
                Mock Get-NetAdapter
                It 'Throws a BindingAdapterNotFoundError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'BindingAdapterNotFoundError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.BindingAdapterNotFoundError `
                            -f $Switches[0].Name,"with a name '$($Switches[0].BindingAdapterName)' ")
                    }
                    $Exception = GetException @ExceptionParameters

                    { Initialize-LabSwitch -Lab $Lab -Switches $Switches } | Should Throw $Exception
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMSwitch -Exactly 1
                    Assert-MockCalled New-VMSwitch -Exactly 0
                    Assert-MockCalled Get-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled Add-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled Set-VMNetworkAdapterVlan -Exactly 0
                    Assert-MockCalled Get-NetAdapter -Exactly 1
                }
            }

            Context 'Valid configuration with External switch with binding Adapter MAC bad' {
                Mock Get-NetAdapter
                $Switches[0].BindingAdapterName = ''
                $Switches[0].BindingAdapterMac = '1111111111'
                It 'Throws a BindingAdapterNotFoundError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'BindingAdapterNotFoundError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.BindingAdapterNotFoundError `
                            -f $Switches[0].Name,"with a MAC address '$($Switches[0].BindingAdapterMac)' ")
                    }
                    $Exception = GetException @ExceptionParameters

                    { Initialize-LabSwitch -Lab $Lab -Switches $Switches } | Should Throw $Exception
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMSwitch -Exactly 1
                    Assert-MockCalled New-VMSwitch -Exactly 0
                    Assert-MockCalled Get-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled Add-VMNetworkAdapter -Exactly 0
                    Assert-MockCalled Set-VMNetworkAdapterVlan -Exactly 0
                    Assert-MockCalled Get-NetAdapter -Exactly 1
                }
            }
        }



        Describe 'Remove-LabSwitch' {

            $Lab = Get-Lab -ConfigPath $Global:TestConfigOKPath
            [LabSwitch[]] $Switches = Get-LabSwitch -Lab $Lab

            Mock Get-VMSwitch -MockWith { $Switches }
            Mock Remove-VMSwitch
            Mock Remove-VMNetworkAdapter

            Context 'Valid configuration is passed' {	
                It 'Does not throw an Exception' {
                    { Remove-LabSwitch -Lab $Lab -Switches $Switches } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMSwitch -Exactly 5
                    Assert-MockCalled Remove-VMSwitch -Exactly 5
                    Assert-MockCalled Remove-VMNetworkAdapter -Exactly 4
                }
            }

            Context 'Valid configuration is passed without switches' {	
                It 'Does not throw an Exception' {
                    { Remove-LabSwitch -Lab $Lab } | Should Not Throw
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMSwitch -Exactly 5
                    Assert-MockCalled Remove-VMSwitch -Exactly 5
                    Assert-MockCalled Remove-VMNetworkAdapter -Exactly 4
                }
            }

            Context 'Valid configuration with blank switch name passed' {	
                $Switches[0].Name = ''
                It 'Throws a SwitchNameIsEmptyError Exception' {
                    $ExceptionParameters = @{
                        errorId = 'SwitchNameIsEmptyError'
                        errorCategory = 'InvalidArgument'
                        errorMessage = $($LocalizedData.SwitchNameIsEmptyError)
                    }
                    $Exception = GetException @ExceptionParameters

                    { Remove-LabSwitch -Lab $Lab -Switches $Switches } | Should Throw $Exception
                }
                It 'Calls Mocked commands' {
                    Assert-MockCalled Get-VMSwitch -Exactly 1
                    Assert-MockCalled Remove-VMSwitch -Exactly 0
                    Assert-MockCalled Remove-VMNetworkAdapter -Exactly 0
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
}
