# coding: utf-8

#=== nanacoギフトID一括登録スクリプト 設定ファイル ===

class Config

  ### nanacoモバイル/nanacoカード 切替 ###
  # true:  nanacoモバイル
  # false: nanacoカード
  USE_MOBILE = false

  # nanacoモバイル カード番号（16桁）
  MOBILE_CARD_NO = 1234567890123456
  # nanacoモバイル パスワード
  MOBILE_PASSWORD = 'YourNanacoPassword'

  # nanacoカード カード番号（16桁）
  CARD_NO = 1234567890123456
  # nanacoカード PIN（7桁）
  CARD_PIN = 1234567

end
