# 更新阿里云DNS

using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Text
using namespace System.Web
using namespace System.Security.Cryptography


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
    $combinedParams = ($paramDict.Keys | Sort-Object { -join ([int[]] $_.ToCharArray()).ForEach('ToString', 'x4') } | ForEach-Object { "$(UrlEncode $_)=$(UrlEncode $paramDict[$_])" }) -join "&"
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
    $queryDict.Signature = UrlEncode (ComputeSignature $method $queryDict)
    "https://alidns.aliyuncs.com/?" + (($queryDict.Keys | ForEach-Object { "$_=$($queryDict[$_])" }) -join "&")
}


function FindDomain {
    $queryDict = @{
        Action = "DescribeDomainRecords";
        DomainName = $domainName;
        PageNumber = 1
    };

    do {
        $url = BuildUrl "GET" $queryDict
        [xml]$xmlContent = (Invoke-WebRequest -Uri $url -Method "GET").Content
        $dnsDomainNode = ($xmlContent | Select-Xml -XPath "/DescribeDomainRecordsResponse/DomainRecords/Record[RR='$dnsRR']" | Select-Object -ExpandProperty node)
        if ($null -ne $dnsDomainNode){
            return $dnsDomainNode.RecordId, $dnsDomainNode.Value
        }
        elseif ([int]$xmlContent.DescribeDomainRecordsResponse.PageSize * [int]$xmlContent.DescribeDomainRecordsResponse.PageNumber -lt [int]$xmlContent.DescribeDomainRecordsResponse.TotalCount){
            $queryDict.PageNumber += 1
        }
        else {
            return $null
        }
    } while ($true)
}


$dnsDomain = FindDomain
if ($null -ne $dnsDomain){
    $recordId, $ipValue = $dnsDomain
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
}