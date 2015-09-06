<#########################################################################################################################################
DSC Template Configuration File For use by LabBuilder
.Title
	MEMBER_DHCP
.Desription
	Builds a Server that is joined to a domain and then made into a DHCP Server.
.Parameters:          
	DomainName = "BMDLAB.COM"
	DomainAdminPassword = "P@ssword!1"
#########################################################################################################################################>

Configuration DC_SECONDARY
{
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	Import-DscResource -ModuleName xActiveDirectory
	Import-DscResource -ModuleName xComputerManagement 
	Node $AllNodes.NodeName {
		# Assemble the Local Admin Credentials
		If ($Node.LocalAdminPassword) {
			[PSCredential]$LocalAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.LocalAdminPassword -AsPlainText -Force))
		}
		If ($Node.DomainAdminPassword) {
			[PSCredential]$DomainAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.DomainAdminPassword -AsPlainText -Force))
		}

        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainName
            DomainUserCredential = $DomainAdminCredential 
            RetryCount = 20 
            RetryIntervalSec = 30 
        }

		xComputer JoinDomain 
        { 
            Name          = $Node.NodeName
            DomainName    = $Node.DomainName
            Credential    = $DomainAdminCredential 
        } 

		WindowsFeature DHCPInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services" 
			DependsOn = "[WindowsFeature]DNSInstall" 
        } 
	}
}