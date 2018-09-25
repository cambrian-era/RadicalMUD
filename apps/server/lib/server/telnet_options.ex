defmodule Server.Telnet.Options do
  @will <<251>>
  @wont <<252>>
  @do_ <<253>>
  @dont <<254>>

  def options do
    %{
      <<0>> => %{
        name: "transmit_binary",
        code: <<0>>,
        responses: %{
          @will => @wont,
          @do_ => @dont,
          @dont => @wont,
          @wont => @dont
        }
      },
      <<1>> => %{
        name: "echo",
        code: <<1>>,
        responses: %{
          @will => @will,
          @do_ => <<251, 1>>,
          @dont => @wont,
          @wont => @dont
        }
      },
      <<5>> => %{
        name: "status",
        code: <<5>>,
        responses: %{
          @will => @wont,
          @do_ => @dont,
          @dont => @wont,
          @wont => @dont
        }
      },
      <<6>> => %{
        name: "timing_mark",
        code: <<6>>,
        responses: %{
          @will => @wont,
          @do_ => @dont,
          @dont => @wont,
          @wont => @dont
        }
      },
      <<21>> => %{
         name: "terminal_type",
          code: <<21>>,
          responses: %{
            @will => @will,
            @do_ => <<251>> <> "xterm",
            @dont => @wont
          }
      },
      <<31>> => %{
        name: "window_size",
         code: <<21>>,
         responses: %{
           @will => @will,
           @do_ => <<251, 0, 80, 0, 24>>,
           @dont => @wont
         }
     },
     <<32>> => %{
        name: "terminal_speed",
        code: <<32>>,
        responses: %{
          @will => @wont,
          @do_ => @dont,
          @dont => @wont,
          @wont => @dont
        }
      }
    }
  end
end