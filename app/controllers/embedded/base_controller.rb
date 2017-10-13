module Embedded
  class BaseController < ApplicationController
    skip_before_action :authenticate

    layout "embedded"
  end
end
