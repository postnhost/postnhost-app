class ApplicationController < ActionController::Base
  include Pagy::Method

  helper Postnhost::CommonCssHelper
  helper Postnhost::ApplicationHelper
  helper Postnhost::CategoryHelper
  helper Postnhost::PublicPagesHelper
  helper Postnhost::SeoHelper

  before_action :set_default_locale

  private

  def set_default_locale
    I18n.locale = I18n.default_locale
  end
end
