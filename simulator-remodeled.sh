#!/bin/bash

############
## Header ##
############

# Author: Eric Guimarães de Sousa Silva
# E-mail: eric.gssilva@gmail.com
# Github: fewbits
# GitLab: eric.gssilva
# Date:   2017-12-08T12:49

##########
## TODO ##
##########
# [-] 2017-12-09 - If I don't have any asset yet, buy at any price and save both Buy and Sell Base Prices
# [X] 2017-12-09 - Add two new attributes to Asset: "assetMinimumPrice" and "assetMaximumPrice" (make them configurable)
# [X] 2017-12-09 - Change logic so, even when everything goes wrong, I never got "Bankrupted"
# [-] 2017-12-09 - Sell Assets only when I have any

############
## Config ##
############
confAssetInitialAmount="0"
confAssetInitialPrice="10.52"
confAssetMinimumPrice="3.83"
confAssetMaximumPrice="100.00"
confAssetName="ITSA4"
confAssetBuyLot="100"
confBrokerInitialBalance="10000.00"
confCheckingInitialBalance="0.00"
confDefaultCurrency="R$"
confDefaultSafeMoney="10000.00"
confDefaultTransferMoney="100.00"
confTimeInitialValue="1"
confTimeUnit="Day"
confTimeDuration="0.1"
confDebug=false

################
## Components ##
################

# Checking
checkingCurrency="${confDefaultCurrency}"
checkingInitialBalance="${confCheckingInitialBalance}"
checkingCurrentBalance="${checkingInitialBalance}"
checkingIdealBalance="${confDefaultSafeMoney}"

checkingDepositFromBroker() {
  # $1 => Amount to transfer
  checkingCurrentBalance=`echo "${checkingCurrentBalance} + ${1}" | bc`
  brokerCurrentBalance=`echo "${brokerCurrentBalance} - ${1}" | bc`
}

checkingGetEnoughMoneyToBrokerBoolean() {
  if [[ `echo "${checkingCurrentBalance} >= ${checkingIdealBalance}" | bc` -eq 1 ]]; then
    return 0
  else
    return 1
  fi
}

# Broker
brokerCurrency="${confDefaultCurrency}"
brokerInitialBalance="${confBrokerInitialBalance}"
brokerCurrentBalance="${brokerInitialBalance}"
brokerIdealBalance="${confDefaultSafeMoney}"

brokerDepositFromChecking() {
  # $1 => Amount to transfer
  brokerCurrentBalance=`echo "${brokerCurrentBalance} + ${1}" | bc`
  checkingCurrentBalance=`echo "${checkingCurrentBalance} - ${1}" | bc`
}

brokerGetEnoughMoneyBoolean() {
  if [[ `echo "${brokerCurrentBalance} >= ${brokerIdealBalance}" | bc` -eq 1 ]]; then
    return 0
  else
    return 1
  fi
}

brokerGetEnoughAssetLotMoneyBoolean() {
  if [[ `echo "${brokerCurrentBalance} >= (${assetCurrentPrice}*${assetBuyLot})" | bc` -eq 1 ]]; then
    return 0
  else
    return 1
  fi
}

brokerGetExtraMoneyBoolean() {
  if [[ `echo "${brokerCurrentBalance} >= (${brokerIdealBalance}+${confDefaultTransferMoney})" | bc` -eq 1 ]]; then
    return 0
  else
    return 1
  fi
}

# Asset
assetName="${confAssetName}"
assetCurrency="${confDefaultCurrency}"
assetInitialPrice="${confAssetInitialPrice}"
assetMinimumPrice="${confAssetMinimumPrice}"
assetMaximumPrice="${confAssetMaximumPrice}"
assetInitialAmount="${confAssetInitialAmount}"
assetCurrentPrice="${assetInitialPrice}"
assetCurrentAmount="${assetInitialAmount}"
assetBalance=`echo "${assetCurrentPrice} * ${assetCurrentAmount}" | bc`
assetBasePriceToBuy=`echo "${assetCurrentPrice} * 0.95" | bc`
assetBasePriceToSell=`echo "${assetCurrentPrice} * 1.05" | bc`
assetBuyLot="${confAssetBuyLot}"

assetBuy() {
  # $1 => Number of assets

  if [[ ${assetCurrentAmount} -eq 0 ]]; then
    assetBasePriceToSell=`echo "${assetCurrentPrice} * 1.05" | bc`
  fi
  assetBasePriceToBuy=`echo "${assetCurrentPrice} * 0.95" | bc`

  assetCurrentAmount=`echo "${assetCurrentAmount} + ${1}" | bc`
  brokerCurrentBalance=`echo "${brokerCurrentBalance} - (${assetCurrentPrice}*${1})" | bc`
}

assetSell() {
  # $1 => Number of assets
  brokerCurrentBalance=`echo "${brokerCurrentBalance} + (${assetCurrentPrice}*${1})" | bc`
  assetCurrentAmount=`echo "${assetCurrentAmount} - ${1}" | bc`
  assetBasePriceToBuy=`echo "${assetCurrentPrice} * 0.95" | bc`
  assetBasePriceToSell=`echo "${assetCurrentPrice} * 1.05" | bc`
}

assetGetInterestBoolean() {
  if [[ `echo "${assetCurrentPrice} >= ${assetBasePriceToSell}" | bc` -eq 1 ]]; then
    return 0
  else
    return 1
  fi
}

assetGetDiscountBoolean() {
  if [[ `echo "${assetCurrentPrice} <= ${assetBasePriceToBuy}" | bc` -eq 1 ]]; then
    return 0
  else
    return 1
  fi
}

# Equity
equityCurrency="${confDefaultCurrency}"
equityBalance=`echo "${checkingCurrentBalance} + ${brokerCurrentBalance} + ${assetBalance}" | bc`

# Time
timeUnit="${confTimeUnit}"
timeInitialValue="${confTimeInitialValue}"
timeCurrentValue="${timeInitialValue}"
timeDuration="${confTimeDuration}"

timePass() {
  # Updating Time
  timeCurrentValue=$((timeCurrentValue+1))
  # Updating Asset Balance
  assetBalance=`echo "${assetCurrentPrice} * ${assetCurrentAmount}" | bc`
  # Updating Equity
  equityBalance=`echo "${checkingCurrentBalance} + ${brokerCurrentBalance} + ${assetBalance}" | bc`
  sleep ${timeDuration}
}

# Screen
screenDraw() {
  clear
  echo "+------------------------------+"
  echo "| Investments Simulator        |"
  echo "+------------------------------+"
  echo "| %             => %           |"
  echo "|                              |"
  echo "| Equity        => %           |"
  echo "|                              |"
  echo "| Checking      => %           |"
  echo "| Broker        => %           |"
  echo "|                              |"
  echo "| Asset Name    => %           |"
  echo "| Asset Price   => %           |"
  echo "| Assets Owned  => %           |"
  echo "| Asset Balance => %           |"
  echo "| Buy At        => %           |"
  echo "| Sell At       => %           |"
  echo "+------------------------------+"

  # Screen editions - Start
  tput civis
  # Time
  tput cup 3 2    ; echo "${timeUnit}"
  tput cup 3 19   ; echo "${timeCurrentValue}"
  # Equity
  tput cup 5 19   ; echo "${equityCurrency}"
  tput cup 5 22   ; echo "${equityBalance}"
  # Checking
  tput cup 7 19   ; echo "${checkingCurrency}"
  tput cup 7 22   ; echo "${checkingCurrentBalance}"
  # Broker
  tput cup 8 19   ; echo "${brokerCurrency}"
  tput cup 8 22   ; echo "${brokerCurrentBalance}"
  # Asset
  tput cup 10 19  ; echo "${assetName}"
  tput cup 11 19  ; echo "${assetCurrency}"
  tput cup 11 22  ; echo "${assetCurrentPrice}"
  tput cup 12 19  ; echo "${assetCurrentAmount}"
  tput cup 13 19  ; echo "${assetCurrency}"
  tput cup 13 22  ; echo "${assetBalance}"
  tput cup 14 19  ; echo "${assetCurrency}"
  tput cup 14 22  ; echo "${assetBasePriceToBuy}"
  tput cup 15 19  ; echo "${assetCurrency}"
  tput cup 15 22  ; echo "${assetBasePriceToSell}"
  # Screen editions - End
  tput cup 18 0
  tput cnorm
}

# Self
selfDecideOperation() {
  selfLogMessage "Do I have extra money in Broker account?"
  if brokerGetExtraMoneyBoolean; then
    selfLogMessage "Yes. I will transfer some money to my Checking account."
    checkingDepositFromBroker "${confDefaultTransferMoney}"
  else
    selfLogMessage "No. That's OK. Let's continue."
    selfLogMessage "The Asset has a good discount?"
    if assetGetDiscountBoolean; then
      selfLogMessage "Yes. Good, I wanna buy some."
      selfLogMessage "Do I have enough money to buy an Asset Lot?"
      if brokerGetEnoughAssetLotMoneyBoolean; then
        selfLogMessage "Yes. Cool, buying an Asset Lot."
        assetBuy ${assetBuyLot}
      else
        selfLogMessage "No. Better wait until the price gets lower."
      fi
    else
      selfLogMessage "No. Not a good time to buy assets."
      selfLogMessage "The Asset has a good interest?"
      if assetGetInterestBoolean; then
        selfLogMessage "Yes. Time to sell my positions."
        assetSell ${assetCurrentAmount}
      else
        selfLogMessage "No. Ok. I'll keep watching the Market..."
      fi
    fi
  fi
}

selfLogMessage() {
  # $1 => Log Message
  if [[ ${confDebug} == "true" ]]; then
    read -p "`date '+[%Y-%m-%d %H:%M]'` Ivee says: $1 (press [ENTER])"
  fi
}

selfGameOver() {
  echo "[GAME OVER] $1"
  exit 1
}

# Market
marketPlay() {
  while [[ true ]]; do
    marketVariatePrices
    screenDraw
    selfLogMessage "A new day is starting on the Wild Market"
    selfLogMessage "Let's see what we have today"
    selfDecideOperation
    selfLogMessage "The day is ending. See you tomorrow."
    timePass
  done
}

marketVariatePrices() {
  # Let's roll a dice to calculate the price variation
  selfDicePriceVariation=`shuf -i 1-6 -n 1`
  
  case ${selfDicePriceVariation} in
    1)
      assetPriceVariation=`echo "${assetCurrentPrice} * 0.01" | bc`
      ;;
    2)
      assetPriceVariation=`echo "${assetCurrentPrice} * 0.01" | bc`
      ;;
    3)
      assetPriceVariation=`echo "${assetCurrentPrice} * 0.01" | bc`
      ;;
    4)
      assetPriceVariation=`echo "${assetCurrentPrice} * 0.02" | bc`
      ;;
    5)
      assetPriceVariation=`echo "${assetCurrentPrice} * 0.03" | bc`
      ;;
    6)
      assetPriceVariation=`echo "${assetCurrentPrice} * 0.20" | bc`
      ;;
  esac

  # Let's roll a dice to decide the operation:
  #   - The price is the same
  #   - The price now is higher
  #   - The price now is lower
  selfDiceOperation=`shuf -i 1-6 -n 1`
  
  case ${selfDiceOperation} in
    1)
      # Nothing
      true
      ;;
    2)
      # Nothing
      true
      ;;
    3)
      # UP - The asset price is higher
      if [[ `echo "${assetCurrentPrice} >= ${assetMaximumPrice}" | bc` -eq 0 ]]; then
        assetCurrentPrice=`echo "${assetCurrentPrice} + ${assetPriceVariation}" | bc`
      fi
      ;;
    4)
      # DOWN - The asset price is lower
      if [[ `echo "${assetCurrentPrice} <= ${assetMinimumPrice}" | bc` -eq 0 ]]; then
        assetCurrentPrice=`echo "${assetCurrentPrice} - ${assetPriceVariation}" | bc`
      fi
      ;;
    5)
      # UP - The asset price is higher
      if [[ `echo "${assetCurrentPrice} >= ${assetMaximumPrice}" | bc` -eq 0 ]]; then
        assetCurrentPrice=`echo "${assetCurrentPrice} + ${assetPriceVariation}" | bc`
      fi
      ;;
    6)
      # DOWN - The asset price is lower
      if [[ `echo "${assetCurrentPrice} <= ${assetMinimumPrice}" | bc` -eq 0 ]]; then
        assetCurrentPrice=`echo "${assetCurrentPrice} - ${assetPriceVariation}" | bc`
      fi
      ;;
  esac

}

############
## Script ##
############

marketPlay
