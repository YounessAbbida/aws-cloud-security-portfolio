# Download Notion attachment images into assets/images (pages must stay public).
$ErrorActionPreference = "Stop"
$portfolioRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$assets = Join-Path $portfolioRoot "assets\images"
$hdr = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" }

function Save-Images([string]$Subdir, [string[]]$Urls) {
  $dir = Join-Path $assets $Subdir
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $n = 1
  foreach ($u in $Urls) {
    $out = Join-Path $dir ("{0:D2}.png" -f $n)
    Invoke-WebRequest -Uri $u -OutFile $out -UseBasicParsing -Headers $hdr
    Write-Host "OK $Subdir $n"
    $n++
  }
}

$lab02 = @(
  "https://www.notion.so/image/attachment%3A21f7e01e-14b4-4611-a466-552af3c197a5%3Aimage.png?table=block&id=31b57009-4627-80e3-9990-c0625d40f5b9&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A88fc7210-9137-4efe-8962-7272de92e74f%3Aimage.png?table=block&id=31b57009-4627-809d-9792-de31c71727b0&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A4600b59f-a221-45f3-9eb1-ddb2e63b9132%3Aimage.png?table=block&id=31b57009-4627-806a-b479-c06dad97dbeb&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A47c37c7a-a074-45bb-872f-9d548da67bb4%3Aimage.png?table=block&id=31b57009-4627-80fd-bced-d37a9ddf39b6&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ade5d995f-3666-4559-b031-f1444ed194bc%3Aimage.png?table=block&id=31b57009-4627-8088-8dc4-c15867c86d20&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A7ad85ab5-4e26-493c-8679-54d378990f9a%3Aimage.png?table=block&id=31b57009-4627-80bf-aa37-ef4537716f0d&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A8ee40c31-9c5b-4142-b3ff-46b66e43075f%3Aimage.png?table=block&id=31b57009-4627-807b-9919-e92528dcc87a&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1360&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A28fb806c-7501-407e-b5b7-2443539b838a%3Aimage.png?table=block&id=31b57009-4627-80c2-bbcd-e7fa37b9072b&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1360&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Aa8f1dd4d-8ed9-4a87-a119-67863ca64c5f%3Aimage.png?table=block&id=31b57009-4627-809a-be41-ee9a52017499&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1360&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A1cec531f-b78e-4e20-afdc-0d661ff6fbe9%3Aimage.png?table=block&id=31b57009-4627-80c0-a835-c1d79ce5c460&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1280&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ae07b852a-670e-45b8-9a41-c0ae2351c1aa%3Aimage.png?table=block&id=31b57009-4627-80fb-ab56-cb96b2e3f65d&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1360&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ae69058da-2b36-4e2b-919d-92c9e2c47336%3Aimage.png?table=block&id=31b57009-4627-80d1-a62f-f8f967994efa&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1360&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac2582e1e-3b60-4285-8dfa-d9c44af88ed3%3Aimage.png?table=block&id=31b57009-4627-8089-89f9-d6752144f217&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1370&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A4752ccd5-a3af-49ed-bb72-557a95f9160b%3Aimage.png?table=block&id=31b57009-4627-8040-a8cf-e22453918655&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1370&userId=&cache=v2"
)

$lab03a = @(
  "https://www.notion.so/image/attachment%3Aa4b6bad9-1f20-469b-ade0-4882e9fb3b89%3Aimage.png?table=block&id=31857009-4627-8002-b7a7-f7ab88b44ea2&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Aee52644f-fe4f-4333-b0ca-c5e8e6d884fa%3Aimage.png?table=block&id=31857009-4627-80c6-80f8-ec96859079cb&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Af728bf07-16a1-4523-adee-69564b8555cb%3Aimage.png?table=block&id=31857009-4627-8099-9a7a-eb558d9c8f4d&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A011a9518-0045-4cfb-9e32-78bdccdba948%3Aimage.png?table=block&id=31857009-4627-80ac-8934-c5d6149e6263&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A7fbb26f6-75f9-4d65-8b8f-3b7ac7c632ef%3Aimage.png?table=block&id=31857009-4627-80df-8144-e9530e0d35cc&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A1a69e7fb-8253-4ae8-b94c-96e59fc51b96%3Aimage.png?table=block&id=31857009-4627-8007-8350-e1c819215f73&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A7f07c936-5839-4ded-9210-0a19be54c06a%3Aimage.png?table=block&id=31857009-4627-80af-8723-c85c0698c17d&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A229639e4-7932-4120-ad3d-d037596039b9%3Aimage.png?table=block&id=31857009-4627-806d-9d49-fa4c4d5e6203&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ad29c073b-0b4b-4821-8e66-88550d9d7a55%3Aimage.png?table=block&id=31857009-4627-8024-ba12-ebb8511a47ef&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Afcd32000-1d6b-43ca-903d-25b344ba0c26%3Aimage.png?table=block&id=31857009-4627-8087-92f5-c9a28e3bcad1&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1410&userId=&cache=v2"
)

$lab03b = @(
  "https://www.notion.so/image/attachment%3A2630980b-e897-423a-a263-8adb5976058b%3Aimage.png?table=block&id=31057009-4627-80ca-b32f-f0f4803c1ddd&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A08d24159-d3f9-48bc-9d86-61814c4daede%3Aimage.png?table=block&id=31057009-4627-8087-942b-e5cd03d7a9ed&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1020&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Aa1e4fbb4-2270-4790-b374-ef15a9974ced%3Aimage.png?table=block&id=31057009-4627-80cf-bf13-d223f7533c3c&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A587ea12c-d9d7-444d-8f96-0fb9dd2c5887%3Aimage.png?table=block&id=31057009-4627-80e6-a9e3-ed0cbd115fac&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac01af084-a935-41b9-919c-e24cab4df93d%3Aimage.png?table=block&id=31057009-4627-8084-a086-d7b8f9732108&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Af01e797a-95bc-48d0-b41a-aade38e772b1%3Aimage.png?table=block&id=31057009-4627-80f8-9716-f0a4b4fb4485&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac2ca72f1-f8a8-49aa-8b97-95fd44b4898a%3Aimage.png?table=block&id=31057009-4627-806a-bb41-e381bc1831b6&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A92f3e57b-6a0a-466c-8fba-ef62c4748576%3AScreenshot_2026-02-23_140656.png?table=block&id=31057009-4627-80c2-9e3a-fba57edbe6ba&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A55528867-8cf7-4a3a-9a03-0dd35eec1be6%3Aimage.png?table=block&id=31057009-4627-802b-b6df-dd26564db112&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Abacd7072-c1bb-49a3-a30c-d67e6a73e172%3Aimage.png?table=block&id=31057009-4627-80d6-80d7-e1a1cd51ba37&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A6270222c-4fdf-4ab6-8fd4-26fe26ff1a09%3Aimage.png?table=block&id=31057009-4627-8047-a079-d0aa0dfcfca4&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Aa256cd1b-5449-4a66-b890-590a9a87571c%3Aimage.png?table=block&id=31057009-4627-8094-a9e4-d7e8f46688b4&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Aa5f0605a-3c66-453a-bfe8-4fa5735d236c%3Aimage.png?table=block&id=31057009-4627-8060-bb40-cbc4cff5b3de&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Aa81037d5-302f-4f85-86f1-65d8731c4adf%3Aimage.png?table=block&id=31057009-4627-807b-aa7f-db5b60b14f48&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ab1272713-9baf-4248-a2d9-367328aaf3e6%3Aimage.png?table=block&id=31057009-4627-80f5-a19c-f7e4acbb114d&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Abb3fb5de-3cee-4025-9a5c-d4c35fb6f529%3Aimage.png?table=block&id=31057009-4627-8005-b29d-dff26470a6fd&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A16916a1a-0266-4b78-9f0c-f54fccd2a803%3Aimage.png?table=block&id=31057009-4627-80dd-b6e3-e7194ce62490&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A610c6186-2da3-4ca2-8601-fd169819b67c%3Aimage.png?table=block&id=31057009-4627-802b-b404-dc8dfaeb8352&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Afd0e18ba-7831-481d-89b9-2f40e190197a%3Aimage.png?table=block&id=31057009-4627-8046-83cf-e22e02cd95f1&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac2d8de6c-74a2-4c09-bd6a-40a5823dbbe5%3Aimage.png?table=block&id=31057009-4627-80a1-892c-d2e97a2127e2&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A316a981b-b274-4dce-bd9a-e6142c2c17c6%3Aimage.png?table=block&id=31057009-4627-807d-ba82-ec7403bd0d9e&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac99ccb1a-f8c1-4e13-a551-e95c7c962ac9%3Aimage.png?table=block&id=31057009-4627-80f5-ab53-c6c77bf08d3f&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Acbcdd32a-d526-4328-bd46-bb21de79ee8f%3Aimage.png?table=block&id=31057009-4627-80c2-a8c2-c2c712c79f3b&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A5342d26d-7fa5-4aa8-8545-f9a90e1ad567%3Aimage.png?table=block&id=31057009-4627-80bc-9916-d4e84b52efbc&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ad1034ecd-0b3f-4773-be11-d6153ce6b7fe%3Aimage.png?table=block&id=31057009-4627-809b-9a52-d7e969358a23&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac76e31f2-d21d-48f8-a53d-9c807c3de4df%3Aimage.png?table=block&id=31057009-4627-80ea-be87-d119710d0cce&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A4d0baf98-a035-4ad0-b5fb-ff897d0a59e2%3Aimage.png?table=block&id=31057009-4627-80fd-b486-ebc6ad31abbf&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ab9e8d3d0-5272-405b-911a-796bc1654063%3Aimage.png?table=block&id=31057009-4627-8060-a870-d3729fce8001&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Af1602ec7-578a-434c-8c0b-7c4bac4398c4%3Aimage.png?table=block&id=31057009-4627-8001-82e7-e7a94fbef054&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1300&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac7217c92-b35c-4044-bcce-044896a055cb%3Aimage.png?table=block&id=31057009-4627-801d-92d0-f566f009d1f7&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2"
)

$lab04 = @(
  "https://www.notion.so/image/attachment%3Ac7635b95-0b43-4d2e-b9c8-1b529edc5400%3AScreenshot_2026-02-16_211349.png?table=block&id=32157009-4627-8096-bc2c-d298142bbac3&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A73713202-dd8c-4afe-ad94-b87da0fe3b24%3AScreenshot_2026-02-16_211532.png?table=block&id=32157009-4627-8008-9785-eae2165824aa&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac16e48c7-7455-4d53-b973-dc15df131adb%3AScreenshot_2026-02-16_211715.png?table=block&id=32157009-4627-8003-bd04-c70c4e55abc5&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=510&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ab48a9133-3ec9-471e-a533-0e2e9665f62d%3AScreenshot_2026-02-16_211809.png?table=block&id=32157009-4627-80c6-b1da-e37325a1c3b6&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ab2a035ba-b60e-4038-bef6-267b8c70b003%3AScreenshot_2026-02-16_211850.png?table=block&id=32157009-4627-80a1-b59c-f4c676729a4b&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A7ba88ab6-9622-4177-8a10-f3eb7b7a60f0%3AScreenshot_2026-02-16_212156.png?table=block&id=32157009-4627-80c5-b315-f999eefed03d&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Adffb0568-46ed-402d-9a3d-9ea89f5a9777%3AScreenshot_2026-02-16_212217.png?table=block&id=32157009-4627-8088-8c31-c9aea0e1c0b0&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac39fb134-b023-4a0d-ac1f-e6dfb4487da6%3AScreenshot_2026-02-16_212310.png?table=block&id=32157009-4627-807c-bacb-f1074dea8ac6&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A19131da7-115d-4971-a867-41c51a80ea2e%3AScreenshot_2026-02-16_212652.png?table=block&id=32157009-4627-8067-82c9-c9756fe93b47&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ac18317ab-d48b-43bb-9655-d05f45e397cc%3AScreenshot_2026-02-16_212719.png?table=block&id=32157009-4627-802c-a949-ef96fd2967de&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A6ac32694-3f91-4b4d-a322-617d5df70c32%3AScreenshot_2026-02-16_213226.png?table=block&id=32157009-4627-80c0-b107-cd01888ab589&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ad5c6ec6b-baea-47e8-8a98-71ae4597e288%3AScreenshot_2026-02-16_213834.png?table=block&id=32157009-4627-80fb-b7c4-d498597ad556&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A853e2198-1df4-4350-b79b-f35bba74c100%3AScreenshot_2026-02-16_213941.png?table=block&id=32157009-4627-8002-b5f7-f79848d720a6&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Aa9a80d1b-ba84-4bcb-932a-00319f71ec4f%3AScreenshot_2026-02-16_214031.png?table=block&id=32157009-4627-80ec-a8cf-e29ddb734c8f&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Aec722261-e15b-4b81-8cc9-08ce9597a349%3AScreenshot_2026-02-16_214049.png?table=block&id=32157009-4627-80df-8b7a-ed7992ea7aa0&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A5b335797-8630-4b82-a173-b84ed22445ce%3AScreenshot_2026-02-16_214213.png?table=block&id=32157009-4627-80ad-b4bf-c5e426600e46&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=990&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3A70d0917e-1c91-4391-a25a-bad2d5a83fd2%3AScreenshot_2026-02-16_214304.png?table=block&id=32157009-4627-80bf-987f-fb92eb2f0769&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2",
  "https://www.notion.so/image/attachment%3Ad24ce9e3-8d9d-40b3-b9dc-7816954a78df%3AScreenshot_2026-02-16_220348.png?table=block&id=32157009-4627-8033-af90-ff64635408a2&spaceId=2366533a-2846-49d9-abe9-d62169c9dd46&width=1420&userId=&cache=v2"
)

Save-Images "lab02-kms-s3-encryption" $lab02
Save-Images "lab03a-vpc-s3-access-point" $lab03a
Save-Images "lab03b-network-firewall-threat-hunting" $lab03b
Save-Images "lab04-aws-config-compliance" $lab04
Write-Host "Done. Assets root: $assets"
