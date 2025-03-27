# 创建全局变量哈希表
$Global:EnvVars = @{}

function Set-GlobalVar {
    param (
        [string]$Key,
        [string]$Value
    )
    $Global:EnvVars[$Key] = $Value
}

function Get-GlobalVar {
    param (
        [string]$Key
    )
    return $Global:EnvVars[$Key]
}

Export-ModuleMember -Function Set-GlobalVar, Get-GlobalVar -Variable EnvVars 