%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2007-2022 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(murmerl3_SUITE).

-compile(nowarn_export_all).
-compile(export_all).

-export([]).

-include_lib("proper/include/proper.hrl").
-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(INT32_MAX, 16#FFFFFFFF).

-type int32() :: 0..?INT32_MAX.

%%%===================================================================
%%% Common Test callbacks
%%%===================================================================

all() ->
    [{group, tests}].

all_tests() -> [hash_32_basics,
                java_basics,
                java_comparison_prop,
                is_right_size_prop].

groups() ->
    [{tests, [], all_tests()}].

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_group(_Group, Config) ->
    %% compile java program
    Dir = ?config(data_dir, Config),
    File = filename:join(Dir, "Murmur3.java"),
    case filelib:is_file(File) of
        true ->
            ok;
        false ->
            Cmd = io_lib:format("javac ~s -s ~s", [File, Dir]),
            Result = os:cmd(Cmd),
            ct:pal("javac result ~p", [Result])
    end,
    Config.

end_per_group(_Group, _Config) ->
    ok.

init_per_testcase(_TestCase, Config) ->
    Config.

end_per_testcase(_TestCase, _Config) ->
    ok.

%%%===================================================================
%%% Test cases
%%%===================================================================

hash_32_basics(_Config) ->
    ?assertEqual(murmerl3:hash_32(""), 0),
    ?assertEqual(murmerl3:hash_32("", 1), 1364076727),
    ?assertEqual(murmerl3:hash_32("Some Data"),
                 murmerl3:hash_32("Some Data", 0)),
    ?assertEqual(murmerl3:hash_32("0"), 3530670207),
    ?assertEqual(murmerl3:hash_32("01"), 1642882560),
    ?assertEqual(murmerl3:hash_32("012"), 3966566284),
    ?assertEqual(murmerl3:hash_32("0123"), 3558446240),
    ?assertEqual(murmerl3:hash_32("01234"), 433070448),
    ok.

java_basics(Config) ->
    %% seed is hardcoded in java program
    Seed = 104729,
    Data = <<"0">>,
    JavaHash = run_java(Data, Config),
    Hash = murmerl3:hash_32(Data, Seed),
    ?assertEqual(JavaHash, Hash),
    ok.

-type c() :: 48..57 | 65..90 | 97..122 .

java_comparison_prop(Config) ->
    Seed = 104729,
    run_proper(
      fun () ->
              ?FORALL(B0, nonempty_list(c()),
                      begin
                          B = unicode:characters_to_binary(B0),
                          % ct:pal("testing ~s", [B]),
                          murmerl3:hash_32(B, Seed) =:= run_java(B, Config)
                      end)
      end, [], 100),

    ok.

is_right_size_prop(_Config) ->
    run_proper(
      fun () ->
              ?FORALL({B, S}, {binary(), int32()},
                      murmerl3:hash_32(B, S) =< ?INT32_MAX)
      end, [], 1000),
    ok.

%% utilities
run_java(Data, Config) ->
    Dir = ?config(data_dir, Config),
    Cmd = io_lib:format("java -cp ~s Murmur3 \"~s\"", [Dir, Data]),
    list_to_integer(string:chomp(os:cmd(Cmd))).

run_proper(Fun, Args, NumTests) ->
    ?assertEqual(
       true,
       proper:counterexample(
         erlang:apply(Fun, Args),
         [{numtests, NumTests},
          {on_output, fun(".", _) -> ok; % don't print the '.'s on new lines
                         (F, A) -> ct:pal(?LOW_IMPORTANCE, F, A) end}])).
