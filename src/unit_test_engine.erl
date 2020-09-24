-module(unit_test_engine).
-export([start/1]).

-include_lib("apptools/include/shorthand.hrl").

%% Exported: test

start([BaseDir|Targets]) ->
  start(BaseDir, Targets, []).

start(BaseDir, [], Modules) ->
    OrderedModules = lists:flatten(lists:reverse(Modules)),
    io:format("Modules: ~p\n", [OrderedModules]),
    done = run(BaseDir, OrderedModules),
    return(0);
start(BaseDir, [Target|Rest], Modules) ->
    case filelib:is_dir(Target) of
        true ->
            Filename = filename:join([Target, "active_unit_tests.dat"]),
            case file:consult(Filename) of
                {ok, ConsultedModules} ->
                    start(BaseDir, Rest,
                          [lists:reverse(ConsultedModules), Modules]);
                {error, Reason} ->
                    io:format(standard_error, "~s: ~s\n",
                              [Filename, file:format_error(Reason)]),
                    return(1)
            end;
        false ->
            start(BaseDir, Rest,
                  [?l2b("unit_test_" ++ Target), Modules])
    end.

return(Status) ->
    erlang:halt(Status).

run(_BaseDir, []) ->
    done;
run(BaseDir, [Module|Rest]) ->
    try
        io:format("******** Module: ~s\n", [Module]),
        apply(?b2a(Module), start, []),
        io:format("++++ SUCCESS!\n\n"),
        run(BaseDir, Rest)
    catch
        Class:Reason:StackTrace ->
            io:format("Class: ~w\nReason: ~p\nStackTrace: ~p\n",
                      [Class, Reason, StackTrace]),
            io:format("---- FAILURE!\n\n"),
            run(BaseDir, Rest)
    end.