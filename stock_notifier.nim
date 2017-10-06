import asyncdispatch, httpclient, strutils, os, browsers, future

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

    return "Currently unavailable" notin content
  except Exception as exc:
    echo("Could not check argos: ", exc.msg)
    return false

proc checkAmazonHasStock(): bool =
  ## Returns true when Amazon contains some stock.
  try:
    echo("Checking amazon")
    let client = newHttpClient("Mozilla/5.0 (Windows NT 10.0; Win64; x64) " &
                               "AppleWebKit/537.36 (KHTML, like Gecko) " &
                               "Chrome/52.0.2743.116 Safari/537.36 Edge/15.15063")
    let content = client.getContent(amazonUrl)
    client.close()
    return "Available from" notin content
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