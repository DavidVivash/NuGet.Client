param([parameter(Mandatory = $true)]
      [string]$OutputPath,
      [parameter(Mandatory = $true)]
      [string]$TemplatePath)

# Make sure we stop on exceptions
$ErrorActionPreference = "Stop"
$FileKind = "{6BB5F8EE-4483-11D3-8BCF-00C04F8EC28C}"

function GetDTE
{
    Write-Host 'Getting dte...'
    return $dte
}

function Get-DTEVersion
{
    $version = [API.Test.VSHelper]::GetVSVersion()
    return $version
}

function New-BuildIntegratedProj
{
    param(
        [string]$ProjectName,
        [string]$SolutionFolder
    )
    
    if ((Get-DTEVersion) -ge '14.0')
    {
        New-Project BuildIntegratedProj $ProjectName $SolutionFolder
    }
    else
    {
        throw "SKIP: $($_)"
    }
}

function New-CpsApp 
{
    param(
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    if ($version -ge '14.0')
    {
        New-Project CpsApp $ProjectName $SolutionFolder
    }
    else
    {
        throw "SKIP: $($_)"
    }
}

function Get-SolutionDir {
    Write-Verbose "Get-SolutionDir function"

    $solutionFullName = Get-SolutionFullName
    return Split-Path $solutionFullName
}

function Get-SolutionFullName {
    Write-Verbose "Get-SolutionFullName function"

    return [API.Test.VSHelper]::GetSolutionFullName()
}

function Close-Solution 
{
    Write-Verbose "Close-Solution function"

    [API.Test.VSHelper]::CloseSolution()
}

function Open-Solution 
{
    param
    (
        [string]
        [parameter(Mandatory = $true)]
        $Path
    )
    Write-Verbose "Open-Solution function"
    
    [API.Test.VSHelper]::OpenSolution($Path)
}

function SaveAs-Solution
{
    param
    (
        [string]
        [parameter(Mandatory = $true)]
        $Path
    )
    Write-Verbose "SaveAs-Solution function"
    
    [API.Test.VSHelper]::SaveAsSolution($Path)
}

function Ensure-Dir {
    param(
        [string]
        [parameter(Mandatory = $true)]
        $Path
    )
    if(!(Test-Path $Path)) {
        mkdir $Path | Out-Null
    }
}

function New-Solution {
    param(
        [string]$solutionName
    )

    Write-Host "New-Solution function"
    if ($solutionName)
    {
        [API.Test.VSHelper]::CreateNewSolution($OutputPath, $solutionName)
    }
    else
    {
        [API.Test.VSHelper]::CreateNewSolution($OutputPath)
    }

    Write-Host "New-Solution function: End"
}

function New-Project {
    param(
         [parameter(Mandatory = $true)]
         [string]$TemplateName,
         [string]$ProjectName,
         [string]$SolutionFolder
    )

    Write-Verbose "New-Project function"
    $p = [API.Test.VSHelper]::NewProject($TemplatePath, $OutputPath, $TemplateName, $ProjectName, $SolutionFolder)
    Write-Verbose "New-Project function end"

    return $p
}

function New-SolutionFolder {
    param(
        [string]$FolderPath
    )

    Write-Verbose "New-SolutionFolder function"
    [API.Test.VSHelper]::NewSolutionFolder($OutputPath, $FolderPath)
    Write-Verbose "New-SolutionFolder function: End"
}

function Rename-SolutionFolder {
    param(
        [string]$FolderPath,
        [string]$NewName
    )

    Write-Verbose "Rename-SolutionFolder function"
    [API.Test.VSHelper]::RenameSolutionFolder($FolderPath, $NewName)
    Write-Verbose "Rename-SolutionFolder function: End"
}

function New-ClassLibrary {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolderName
    )

    New-Project ClassLibrary $ProjectName $SolutionFolderName
}

function New-LightSwitchApplication 
{
    param(
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project JScriptVisualBasicLightSwitchProjectTemplate $ProjectName $SolutionFolder
}

function New-PortableLibrary 
{
    param(
        [string]$ProjectName,
        [string]$Profile = $null,
        [string]$SolutionFolder
    )

    try
    {
        $project = New-Project PortableClassLibrary $ProjectName $SolutionFolder
    }
    catch {
        # If we're unable to create the project that means we probably don't have some SDK installed
        # Signal to the runner that we want to skip this test        
        throw "SKIP: $($_)"
    }

    if ($Profile) 
    {
        $name = $project.Name
        $project.Properties.Item("TargetFrameworkMoniker").Value = ".NETPortable,Version=v4.0,Profile=$Profile"
        $project = Get-Project -Name $name
    }

    $project
}

function New-JavaScriptApplication 
{
    param(
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    try 
    {
        if (Get-DTEVersion -eq '12.0')
        {
            New-Project WinJSBlue $ProjectName $SolutionFolder
        }
        elseif (Get-DTEVersion -eq '14.0')
        {
            New-Project WinJS_Dev14 $ProjectName $SolutionFolder
        }
        else 
        {
            New-Project WinJS $ProjectName $SolutionFolder
        }
    }
    catch {
        # If we're unable to create the project that means we probably don't have some SDK installed
        # Signal to the runner that we want to skip this test        
        throw "SKIP: $($_)"
    }
}

function New-JavaScriptApplication81 
{
    param(
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    try 
    {
        New-Project WinJSBlue $ProjectName $SolutionFolder
    }
    catch {
        # If we're unable to create the project that means we probably don't have some SDK installed
        # Signal to the runner that we want to skip this test        
        throw "SKIP: $($_)"
    }
}

function New-JavaScriptWindowsPhoneApp81 
{
    param(
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    try 
    {
        New-Project WindowsPhoneApp81JS $ProjectName $SolutionFolder
    }
    catch {
        # If we're unable to create the project that means we probably don't have some SDK installed
        # Signal to the runner that we want to skip this test
        throw "SKIP: $($_)"
    }
}

function New-NativeWinStoreApplication
{
    param(
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    try
    {
        if (Get-DTEVersion -eq '12.0' -or Get-DTEVersion -eq '14.0')
        {
            New-Project CppWinStoreApplicationBlue $ProjectName $SolutionFolder
        }
        elseif (Get-DTEVersion -eq '14.0')
        {
            New-Project CppWinStoreApplication_Dev14 $ProjectName $SolutionFolder
        }
        else 
        {
            New-Project CppWinStoreApplication $ProjectName $SolutionFolder
        }
    }
    catch {
        # If we're unable to create the project that means we probably don't have some SDK installed
        # Signal to the runner that we want to skip this test        
        throw "SKIP: $($_)"
    }
}

function New-ConsoleApplication {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project ConsoleApplication $ProjectName $SolutionFolder
}

function New-WebApplication {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project EmptyWebApplicationProject40 $ProjectName $SolutionFolder
}

function New-VBConsoleApplication {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project VBConsoleApplication $ProjectName $SolutionFolder
}

function New-MvcApplication { 
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project EmptyMvcWebApplicationProjectTemplatev4.0.csaspx $ProjectName $SolutionFolder
}

function New-MvcWebSite { 
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project WebApplication45WebSite $ProjectName $SolutionFolder
}

function New-WebSite {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project EmptyWeb $ProjectName $SolutionFolder
}

function New-FSharpLibrary {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project FSharpLibrary $ProjectName $SolutionFolder
}

function New-FSharpConsoleApplication {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project FSharpConsoleApplication $ProjectName $SolutionFolder
}

function New-WPFApplication {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project WPFApplication $ProjectName $SolutionFolder
}

function New-SilverlightClassLibrary {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project SilverlightClassLibrary $ProjectName $SolutionFolder
}

function New-SilverlightApplication {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    New-Project SilverlightProject $ProjectName $SolutionFolder
}

function New-WindowsPhoneClassLibrary {
    param(        
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    try {
        if (Get-DTEVersion -eq '14.0') {
            New-Project WindowsPhoneClassLibrary81 $ProjectName $SolutionFolder
        }
        else {
            New-Project WindowsPhoneClassLibrary $ProjectName $SolutionFolder
        }
    }
    catch {
        # If we're unable to create the project that means we probably don't have some SDK installed
        # Signal to the runner that we want to skip this test        
        throw "SKIP: $($_)"
    }
}

function New-DNXClassLibrary
{
    param(
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    try 
    {
        New-Project DNXClassLibrary $ProjectName $SolutionFolder
    }
    catch {
        # If we're unable to create the project that means we probably don't have some SDK installed
        # Signal to the runner that we want to skip this test        
        throw "SKIP: $($_)"
    }
}

function New-DNXConsoleApp
{
    param(
        [string]$ProjectName,
        [string]$SolutionFolder
    )

    try 
    {
        New-Project DNXConsoleApp $ProjectName $SolutionFolder
    }
    catch {
        # If we're unable to create the project that means we probably don't have some SDK installed
        # Signal to the runner that we want to skip this test        
        throw "SKIP: $($_)"
    }
}

function New-TextFile {
    (GetDTE).ItemOperations.NewFile('General\Text File')
    (GetDTE).ActiveDocument.Object("TextDocument")
}

function Build-Project {
    param(
        [parameter(Mandatory = $true)]
        $Project,
        [string]$Configuration
    )    
    if(!$Configuration) {
        # If no configuration was specified then use
        $Configuration = (GetDTE).Solution.SolutionBuild.ActiveConfiguration.Name
    }
    
    # Build the project and wait for it to complete
    (GetDTE).Solution.SolutionBuild.BuildProject($Configuration, $Project.UniqueName, $true)
}

function Clean-Project {
    # Clean the project and wait for it to complete
    (GetDTE).Solution.SolutionBuild.Clean($true)
}

function Build-Solution {
    # Build and wait for it to complete
    (GetDTE).Solution.SolutionBuild.Build($true)
}

function Get-AssemblyReference {
    param(
        [parameter(Mandatory = $true)]
        $Project,
        [parameter(Mandatory = $true)]
        [string]$Reference
    )    
    try {
        return $Project.Object.References.Item($Reference)
    }
    catch {        
    }
    return $null
}

function Get-PropertyValue {
    param(
        [parameter(Mandatory = $true)]
        $Project,
        [parameter(Mandatory = $true)]
        [string]$PropertyName
    )    
    try {
        $property = $Project.Properties.Item($PropertyName)        
        if($property) {
            return $property.Value
        }
    }
    catch {        
    }
    return $null
}

function Get-MsBuildPropertyValue {
    param(
        [parameter(Mandatory = $true)]
        $Project,
        [parameter(Mandatory = $true)]
        [string]$PropertyName
    )    

    $msBuildProject = Get-MsBuildProject $project
    return $msBuildProject.GetPropertyValue($PropertyName)

    return $null
}

function Get-MsBuildProject 
{
    param(
        [parameter(Mandatory = $true)]
        $project
    )

    $projectCollection = [Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection

    $loadedProjects = $projectCollection.GetLoadedProjects($project.FullName)
    if ($loadedProjects.Count -gt 0) {
        foreach ($p in $loadedProjects) {
            return $p
        }
    }

    $projectCollection.LoadProject($project.FullName)
}

function Get-ProjectDir {
    param(
        [parameter(Mandatory = $true)]
        $Project
    )

    # c++ project has ProjectDirectory
    $path = Get-PropertyValue $Project 'ProjectDirectory'
    if ($path) 
    {
        return $path
    }

    $path = Get-PropertyValue $Project FullPath
    if ($path)
    {
        if ([System.IO.File]::Exists($path))
        {
            $path = Split-Path $path -Parent
        }
    }

    $path
}

function Get-ProjectName 
{
    param(
        [parameter(Mandatory = $true)]
        $Project
    )
    
    $projectName = $Project.Name

    if ($project.Type -eq 'Web Site' -and $project.Properties.Item("WebSiteType").Value -eq "0") 
    {
        # If this is a WebSite project and WebSiteType = 0, meaning it's configured to use Casini as opposed to IIS Express, 
        # then $Project.Name will return the full path to the website directory. We don't want to use the full path, thus
        # we extract the directory name out of it.

        $projectName = Split-Path -Leaf $projectName
    }
    
    $projectName
}

function Get-OutputPath {
    param(
        [parameter(Mandatory = $true)]
        $Project
    )
    
    $outputPath = $Project.ConfigurationManager.ActiveConfiguration.Properties.Item("OutputPath").Value
    Join-Path (Get-ProjectDir) $outputPath
}

function Get-ErrorTasks {
    param(
        [parameter(Mandatory = $true)]
        $vsBuildErrorLevel
    )
    (GetDTE).ExecuteCommand("View.ErrorList", " ")
    
    # Make sure there are no errors in the error list
    $errorList = (GetDTE).Windows | ?{ $_.Caption -like 'Error List*' } | Select -First 1
    
    if(!$errorList) {
        throw "Unable to locate the error list"
    }

    # Forcefully show all the error items so that they can be retrieved when they are present
    $errorList.Object.ShowErrors = $True
    $errorList.Object.ShowWarnings = $True
    $errorList.Object.ShowMessages = $True
    
    # Get the list of errors from the error list window which contains errors, warnings and info
    $allItemsInErrorListWindow = $errorList.Object.ErrorItems

    $errorTasks = @()
    for($i=0; $i -lt $allItemsInErrorListWindow.Count; $i++)
    {
        $currentErrorLevel = [EnvDTE80.vsBuildErrorLevel]($allItemsInErrorListWindow[$i].ErrorLevel)
        if($currentErrorLevel -eq $vsBuildErrorLevel)
        {
            $errorTasks += $allItemsInErrorListWindow[$i]
        }
    }

    # Force return array. Arrays are zero-based
    return ,$errorTasks
}

function Get-Errors {
    $vsBuildErrorLevelHigh = [EnvDTE80.vsBuildErrorLevel]::vsBuildErrorLevelHigh
    $errors = Get-ErrorTasks $vsBuildErrorLevelHigh

    # Force return array. Arrays are zero-based
    return ,$errors
}

function Get-Warnings {
    $vsBuildErrorLevelMedium = [EnvDTE80.vsBuildErrorLevel]::vsBuildErrorLevelMedium
    $warnings = Get-ErrorTasks $vsBuildErrorLevelMedium

    # Force return array. Arrays are zero-based
    return ,$warnings
}

function Get-ProjectItemPath {
    param(
        [parameter(Mandatory = $true)]
        $Project,
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path
    )
    $item = Get-ProjectItem $Project $Path
    
    if($item) {
        return $item.Properties.Item("FullPath").Value
    }
}

function Remove-ProjectItem {
    param(
        [parameter(Mandatory = $true)]
        $Project,
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path
    )

    $item = Get-ProjectItem $Project $Path
    $path = Get-ProjectItemPath $Project $Path
    $item.Remove()
    Remove-Item $path
}

function Get-ProjectItem {
    param(
        [parameter(Mandatory = $true)]
        $Project,
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path
    )
    Process {
        $pathParts = $Path.Split('\')
        $projectItems = $Project.ProjectItems
        
        foreach($part in $pathParts) {
            if(!$part -or $part -eq '') {
                continue
            }
            
            try {
                $subItem = $projectItems.Item($part)
            }
            catch {
                return $null
            }

            $projectItems = $subItem.ProjectItems
        }

        if($subItem.Kind -eq $FileKind) {
            return $subItem
        }
        
        # Force array
       return  ,$projectItems
    }
}

function Add-ProjectReference {
    param (
        [parameter(Mandatory = $true)]
        $ProjectFrom,
        [parameter(Mandatory = $true)]
        $ProjectTo
    )

    if($ProjectFrom.Object.References.AddProject) {
        $ProjectFrom.Object.References.AddProject($ProjectTo) | Out-Null
    }
    elseif($ProjectFrom.Object.References.AddFromProject) {
        $ProjectFrom.Object.References.AddFromProject($ProjectTo) | Out-Null
    }
}

function Remove-Project {
    param (
        [parameter(Mandatory = $true)]
        $ProjectName
    )

    [NuGetConsole.Host.PowerShell.Implementation.ProjectExtensions]::RemoveProject($ProjectName)
}

function Enable-PackageRestore {
    if (!([API.Test.VSHelper]::IsSolutionAvailable()))
    {
        throw "No solution is available."
    }

    $componentService = Get-VSComponentModel
    
    # change active package source to "All"
    $packageSourceProvider = $componentService.GetService([NuGet.VisualStudio.IVsPackageSourceProvider])
    $packageSourceProvider.ActivePackageSource = [NuGet.VisualStudio.AggregatePackageSource]::Instance
    
    $packageRestoreManager = $componentService.GetService([NuGet.VisualStudio.IPackageRestoreManager])
    $packageRestoreManager.EnableCurrentSolutionForRestore($false)
}

function Check-NuGetConfig {
    # Create an empty NuGet.Config file if not exist. It will happen on machines with visual studio newly installed.
    $nuGetConfigPath = Join-Path $env:AppData 'NuGet\NuGet.Config'
    if (!(Test-Path $nuGetConfigPath))
    {
        $newFile = New-Item $nuGetConfigPath -ItemType File
        '<?xml version="1.0" encoding="utf-8"?>
        <configuration>
        </configuration>' > $newFile
    }
}

function Get-BuildOutput { 
    return [API.Test.VSHelper]::GetBuildOutput()
}