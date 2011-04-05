# The method below was borrowed - with very minor modification - from Chu Yeow's example at:
# http://blog.codefront.net/2008/01/14/retrying-code-blocks-in-ruby-on-exceptions-whatever/
#
# Options:
# * :tries - Number of retries to perform. Defaults to 3.
# * :retry_on - The Exception on which a retry will be performed.
#         Defaults to Exception, which retries on any Exception.
# * :sleep_between_tries - Number of seconds to sleep between each retry.
#               Defaults to not sleeping.  Sleep 0 here means don't sleep, not sleep forever.
#
# Example
# =======
#   retry_block(:tries => 5, :retry_on => OpenURI::HTTPError) do
#     # your code here
#   end
#
class Object
  def retry_block(options = {}, &block)
    opts = options.reverse_merge(:tries => 3, :retry_on => Exception, :sleep_between_tries => 0)
    retry_exception, retries, sleep_for = opts[:retry_on], opts[:tries], opts[:sleep_between_tries].round

    begin
      return yield
    rescue retry_exception
      sleep sleep_for if sleep_for > 0
      retry if (retries -= 1) > 0
    end

    yield
  end
end
