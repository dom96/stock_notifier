import asyncdispatch, httpclient, strutils, os, browsers, future, times, re

import notifications/macosx

const
  argosUrl = "http://www.argos.co.uk/Product/7366077"
  amazonUrl = "https://www.amazon.co.uk/Nintendo-Classic-Mini-" &
              "Entertainment-System/dp/B073BVHY3F"

proc onNotificationClick(info: ClickInfo, url: string) =
  if info.kind == ClickKind.ActionButtonClicked:
    openDefaultBrowser(url)

proc checkArgosHasStock(): bool =
  ## Returns true when Argos contains some stock.
  try:
    echo("Checking argos")
    let client = newHttpClient()
    let content = client.getContent(argosUrl)
    client.close()

    result = "Currently unavailable" notin content
    if result:
      writeFile(getCurrentDir() / ("argos-yes-body-" & $epochTime()), content)
  except Exception as exc:
    echo("Could not check argos: ", exc.msg)
    return false

proc checkAmazonHasStock(): bool =
  ## Returns true when Amazon contains some stock.
  try:
    echo("Checking amazon")
    let client = newHttpClient("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:56.0) Gecko/20100101 Firefox/56.0")
    let request = client.get(amazonUrl)
    let content = request.body
    if request.status != Http200:
      writeFile(getCurrentDir() /
                ("amazon-$#-body-$#" % [request.status, $epochTime()]), content)
      raise newException(HttpRequestError, request.status)

    client.close()

    let pattern = re"<span id=""priceblock_ourprice"" class=""a-size-medium a-color-price"">(.+?)<\/span>"
    var matches: array[1, string]
    var price = 200.0
    if content.find(pattern, matches) != -1:
      price = parseFloat(matches[0][len("£") .. ^1])

    result = "Available from" notin content and
             price < 90.0

    if result:
      writeFile(getCurrentDir() / ("amazon-yes-body-" & $epochTime()), content)
  except Exception as exc:
    echo("Could not check amazon: ", exc.msg)
    return false

while true:
  echo("Checking stock...")
  if checkArgosHasStock():
    var center = newNotificationCenter(
      (info: ClickInfo) => onNotificationClick(info, argosUrl)
    )
    waitFor center.show("In Stock", "Argos has stock!", actionButtonTitle="Open")

  if checkAmazonHasStock():
    var center = newNotificationCenter(
      (info: ClickInfo) => onNotificationClick(info, amazonUrl)
    )
    waitFor center.show("In Stock", "Amazon has stock!",
                        actionButtonTitle="Open")

  sleep(60000*2)