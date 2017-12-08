#!/bin/bash

############
## Header ##
############

# Author: Eric Guimarães de Sousa Silva
# E-mail: eric.gssilva@gmail.com
# Github: fewbits
# GitLab: eric.gssilva
# Date:   2017-12-06T11:29

###################
## Configuration ##
###################
confBankInitialBalance="0"
confBrokerInitialBalance="1000"
confAssetName="ITSA4"
confAssetInitialPrice="10.50"
confAssetInitialAmount="0"
confBrokerDesiredBalance="300"
confBrokerDepositAmount="100"
confAssetPriceChange="0.01"

###############
## Constants ##
###############
constantTimeInitialValue="1"
constantTimeDuration="0.2"
constantTimeUnit="Day"
constantMoneyCurrency="R$"

###############
## Functions ##
###############

assetGetNewPrice() {
  # Let's calculate the value of the change
  walletAssetChange=`echo "${walletAssetPrice} * ${confAssetPriceChange}" | bc`

  # Let's roll the dice to decide if:
  #   - The price is the same
  #   - The price now is higher
  #   - The price now is lower
  diceNumber=`shuf -i 1-6 -n 1`
  
  case ${diceNumber} in
    1)
      # Nothing - The asset price (and the song) remains the same
      walletAssetPrice=${walletAssetPrice}
      ;;
    2)
      # Nothing - The asset price (and the song) remains the same
      walletAssetPrice=${walletAssetPrice}
      ;;
    3)
      # Nothing - The asset price (and the song) remains the same
      walletAssetPrice=${walletAssetPrice}
      ;;
    4)
      # Nothing - The asset price (and the song) remains the same
      walletAssetPrice=${walletAssetPrice}
      ;;
    5)
      # UP - The asset price is higher
      walletAssetPrice=`echo "${walletAssetPrice} + ${walletAssetChange}" | bc`
      ;;
    6)
      # DOWN - The asset price is lower
      walletAssetPrice=`echo "${walletAssetPrice} - ${walletAssetChange}" | bc`
      ;;
  esac
}

decideAssetBuy() {
  # If I don't have an asset
  #   THEN
  # I should buy one and register how much I have paid
  #
  #   ALSO...
  #
  # If <thinking...>
  
  # Initial Buy
  if [[ ${walletAssetAmount} -eq 0 ]] && [[ `echo "${walletBrokerBalance} > ${walletAssetPrice}" | bc` -eq 1 ]]; then
    walletBrokerBalance=`echo "${walletBrokerBalance} - ${walletAssetPrice}" | bc`
    walletAssetAmount=$((walletAssetAmount+1))
    walletAssetFirstPrice=${walletAssetPrice}
  elif [[ `echo "${walletBrokerBalance} > ${walletAssetPrice}" | bc` -eq 1 ]] && [[ `echo "${walletAssetPrice} < ${walletAssetFirstPrice}" | bc` -eq 1 ]]; then
    walletBrokerBalance=`echo "${walletBrokerBalance} - ${walletAssetPrice}" | bc`
    walletAssetAmount=$((walletAssetAmount+1))
  fi
}

decideAssetSell() {
  # If I don't have an asset
  #   THEN
  # I should buy one and register how much I paid
  #
  #   ALSO...
  #
  # If <thinking...>
  
  if [[ `echo "${walletAssetAmount} > 0" | bc` -eq 1 ]] && [[ `echo "${walletAssetPrice} > ${walletAssetFirstPrice}" | bc` -eq 1 ]]; then
    walletBrokerBalance=`echo "${walletBrokerBalance} + ${walletAssetPrice}" | bc`
    walletAssetAmount=$((walletAssetAmount-1))
  fi
}

decideBrokerDeposit() {
  # If I have money in the bank
  #   AND
  # I don't have enough money in broker account
  #   THEN
  # I should deposit in broker account

  if [[ `echo "${walletBankBalance} > ${confBrokerDesiredBalance}" | bc` -eq 1 ]] && [[ `echo "${walletBrokerBalance} < ${confBrokerDesiredBalance}" | bc` -eq 1 ]]; then
    walletBankBalance=`echo "${walletBankBalance} - ${confBrokerDepositAmount}" | bc`
    walletBrokerBalance=`echo "${walletBrokerBalance} + ${confBrokerDepositAmount}" | bc`
  fi
}

decideBrokerWithdraw() {
  # If the broker account balance is:
  #   - The desired balance
  #       +
  #   - The deposit amount
  #   THEN
  # I should withdraw from the broker account

  if [[ ${walletBrokerBalance} -gt ${confBrokerDesiredBalance}+${confBrokerDepositAmount} ]]; then
    walletBrokerBalance=`echo "${walletBrokerBalance} - ${confBrokerDepositAmount}" | bc`
    walletBankBalance=`echo "${walletBankBalance} + ${confBrokerDepositAmount}" | bc`
  fi
}

marketRun() {
  # It's a new day in the Wild Market
  timePass

  # Let's check the new Asset's price
  assetGetNewPrice

  # Should I deposit in broker account?
  decideBrokerDeposit
  # Should I withdraw from broker account?
  decideBrokerWithdraw
  # Should I buy an asset?
  decideAssetBuy
  # Should I sell an asset?
  decideAssetSell

  # Let's see the result...
  screenDraw
  
  # Let's wait until the time pass...
  sleep ${constantTimeDuration}
}

screenDraw() {
  clear
  walletUpdateTotals
  echo "======== Investments Simulator ========"
  echo
  echo "${constantTimeUnit}: ${walletTimeValue} | Base Price: ${walletAssetFirstPrice}"
  echo
  echo "[ ---- BANK ---- ]"
  echo "Bank Balance: ${constantMoneyCurrency}${walletBankBalance}"
  echo
  echo "[ ---- BROKER ---- ]"
  echo "Broker Balance: ${constantMoneyCurrency}${walletBrokerBalance}"
  echo
  echo "[ ---- STOCKS ---- ]"
  echo "Asset Name: ${confAssetName}"
  echo "Asset Price: ${constantMoneyCurrency}${walletAssetPrice}"
  echo "Asset Amount: ${walletAssetAmount}"
  echo "Asset Balance: ${constantMoneyCurrency}${walletAssetBalance}"
  echo
  echo "[ ---- TOTAL ---- ]"
  echo "Patrimony: ${constantMoneyCurrency}${walletBalance}"
}

screenGetSize() {
  screenWidth=`tput cols`
  screenHeight=`tput lines`
}

timePass() {
  walletTimeValue=$((walletTimeValue+1))
}

walletSetInitialValues() {
  # Getting the initial values
  walletBankBalance="${confBankInitialBalance}"
  walletBrokerBalance="${confBrokerInitialBalance}"
  walletTimeValue="${constantTimeInitialValue}"
  walletAssetAmount="${confAssetInitialAmount}"
  walletAssetPrice="${confAssetInitialPrice}"
}

walletUpdateTotals() {
  walletAssetBalance=`echo "${walletAssetAmount} * ${walletAssetPrice}" | bc`
  walletBalance=`echo "${walletBankBalance} + ${walletBrokerBalance} + ${walletAssetBalance}" | bc`
}

############
## Script ##
############

# Let's generate the Initial Values
walletSetInitialValues
screenDraw
sleep ${constantTimeDuration}

# Let's watch the wild Market in action
while [ true ]; do
  marketRun
done
