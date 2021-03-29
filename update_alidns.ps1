# 更新阿里云DNS

using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Text
using namespace System.Web
using namespace System.Security.Cryptography

$aliUrlPrefix = "https://alidns.aliyuncs.com/?"
$accessKeyId = "YOUR_KEY_ID"                    # AccessKeyId
$accessKeySecret = "YOUR_KEY_SECRET"            # AccessKeySecret
$domainName = "microbubu.com"                   # domain eg: microbubu.com
$dnsRR = "dns"                                  # rr eg: dns (dns.microbubu.com)

function UrlEncode {
    param (
        [string]$url
    )
    -join ($url.ToCharArray() | ForEach-Object { $encode = [HttpUtility]::UrlEncode($_.ToString());  if ($encode.Length -gt 1) { $encode.ToUpper() } else { $encode }})
}

function ComputeSignature {
    param (
        [string]$method,
        [hashtable]$paramDict
    )
    
    $combinedParams = ($paramDict.keys | Sort-Object | ForEach-Object { "$(UrlEncode $_)=$(UrlEncode $paramDict[$_])" }) -join "&"
    $stringToSign = $method.ToUpper() + "&" + (UrlEncode "/") + "&" + (UrlEncode $combinedParams)
    $hasher = [HMACSHA1]::new([Encoding]::UTF8.GetBytes($accessKeySecret + "&"))
    $hashedBytes = $hasher.ComputeHash([Encoding]::UTF8.GetBytes($stringToSign))
    [Convert]::ToBase64String($hashedBytes)
}

function BuildUrl {
    param (
        [string]$method,
        [hashtable]$paramDict
    )

    $queryDict = @{
        Format = "xml";
        Version = "2015-01-09";
        AccessKeyId = $accessKeyId;
        Timestamp = [datetime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");
        SignatureMethod = "HMAC-SHA1";
        SignatureVersion = "1.0";
        SignatureNonce = [random]::new().Next().ToString();
    }
    $paramDict.Keys | ForEach-Object { $queryDict.Add($_, $paramDict[$_]) }
    $queryDict = GetRequstParamsDict $paramDict
    $queryDict.Signature = UrlEncode (ComputeSignature $method $queryDict)
    $aliUrlPrefix + (($queryDict.Keys | ForEach-Object { "$_=$($queryDict[$_])" }) -join "&")
}

function FindDomain {
    $queryDict = @{
        Action = "DescribeDomainRecords";
        DomainName = $domainName;
        PageNumber = 1
    };
    $isFind 
    do {
        $url = BuildUrl "GET" $queryDict
        $listDomainResponse = Invoke-WebRequest -Uri $url -Method "GET"
        $dnsDomainNode = ([xml]$listDomainResponse.Content | Select-Xml -XPath "/DescribeDomainRecordsResponse/DomainRecords/Record[RR='$dnsRR']" | Select-Object -ExpandProperty node)
        if ($null -ne $dnsDomainNode){
            $dnsDomainNode.RecordId
            $dnsDomainNode.Value
            return
        }
        else {
            $queryDict.PageNumber += 1
        }
    } while (1 -eq 1)
}


$dnsDomain = FindDomain
$recordId = $dnsDomain[1]
$ipValue = $dnsDomain[2]
$myIp = (Invoke-WebRequest -Uri "http://whatismyip.akamai.com").Content
if ($ipValue -ne $myIp){
    $queryDict = @{
        Action = "UpdateDomainRecord";
        RR = $dnsRR;
        RecordId = $recordId;
        Type = "A";
        Value = $myIp
    };
    $url = BuildUrl "GET" $queryDict
    Invoke-WebRequest -Uri $url -Method "GET"
}