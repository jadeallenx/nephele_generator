-module(nephele_generator).

%% API exports
-export([main/1]).

%%====================================================================
%% API functions
%%====================================================================

%% escript Entry point
main(Args) ->

    true = ( 3 == length(Args) andalso
      lists:all(fun(E) -> is_list(E) andalso filelib:is_dir(E) end, Args)),

    io:format(user, "Args: ~n~p~n", [Args]),

    [ApiSrc, TemplateDir, OutputDir] = Args,

    Templates = load_templates(TemplateDir),
    Files = walk_api_src([ApiSrc], []),
    build_modules(Templates, Files, OutputDir),

    erlang:halt(0).

%%====================================================================
%% Internal functions
%%====================================================================

load_templates(TemplateDir) ->
    {ok, Filenames} = file:list_dir(TemplateDir),
    lists:foldl(fun load_file/2, #{},
                [ filename:join(TemplateDir, F) || F <- Filenames ]).

load_file(File, M) ->
    {ok, Data} = file:read_file(File),
    Template = bbmustache:parse_binary(Data),
    maps:put(filename_to_binary_key(File), Template, M).

filename_to_binary_key(F) ->
    [File, _Ext] = string:split(filename:basename(F), "."),
    list_to_binary(File).

walk_api_src([], Acc) -> lists:reverse(Acc);
walk_api_src([H|T], Acc) ->
    {ok, Fs} = file:list_dir(H),
    Paths = [ filename:join(H, F) || F <- Fs ],
    {Dirs, Files} = lists:partition(fun(F) -> filelib:is_dir(F) end, Paths),
    NewAcc = case Files of
        [] -> Acc;
        _  -> [ Files | Acc ]
    end,
    NewDirs = pick_latest_date_dir(H, Dirs),
    walk_api_src( lists:append(T, NewDirs), NewAcc).

pick_latest_date_dir(Current, Ds) ->
    {DateDirs, OtherDirs} = lists:partition(fun(N) -> "20" =:= string:sub_string(N, 1, 2) end,
                                            [ filename:basename(D) || D <- Ds ]),
    case DateDirs of
        [] ->
            Ds;
        _ ->
            Latest = pick_latest_date(DateDirs),
            [ filename:join(Current, D) || D <- [ Latest | OtherDirs ] ]
    end.

pick_latest_date(Ds) ->
    lists:last(lists:sort(Ds)).

build_modules(Templates, Files, OutputDir) ->
    io:format("Templates: ~p~n", [Templates]),
    io:format("Files: ~p~n", [Files]),
    io:format("OutputDir: ~p~n", [OutputDir]).



