module Main exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Html exposing (Html, text, div, h1, h2, ul, li, a)
import Html.Attributes exposing (href)
import Phoenix
import Phoenix.Socket as Socket
import Phoenix.Channel as Channel
import Phoenix.Push as Push


wsServer : String
wsServer =
    "ws://localhost:4000/socket/websocket"



---- Decoders ----


hackerNewsDecoder : Decoder (List Story)
hackerNewsDecoder =
    Decode.field "stories"
        (Decode.list
            (Decode.map3 Story
                (Decode.field "title" Decode.string)
                (Decode.field "url" Decode.string)
                (Decode.field "score" Decode.int)
            )
        )


decodeHackerNews : Decode.Value -> Msg
decodeHackerNews result =
    case Decode.decodeValue hackerNewsDecoder result of
        Ok stories ->
            News stories

        _ ->
            NoOp



---- MODEL ----


type Msg
    = NewMsg Decode.Value
    | News (List Story)
    | NoOp


type alias Story =
    { title : String, url : String, score : Int }


type alias Model =
    { hackerNewsStories : List Story }


init : ( Model, Cmd Msg )
init =
    ( { hackerNewsStories = [] }, (Push.init "news:lobby" "HackerNews") |> Push.onOk decodeHackerNews |> Phoenix.push wsServer )



---- UPDATE ----


socket : Socket.Socket Msg
socket =
    Socket.init wsServer


channel : Channel.Channel Msg
channel =
    Channel.init "news:lobby"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        News stories ->
            ( { model | hackerNewsStories = stories }, Cmd.none )

        NewMsg _ ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ h1 []
            [ text "Dashboard" ]
        , toDoListView model
        , hackerNewsView model.hackerNewsStories
        ]


toDoListView : Model -> Html Msg
toDoListView model =
    div []
        [ h2 [] [ text "To Do List" ]
        ]


hackerNewsView : List Story -> Html Msg
hackerNewsView stories =
    div []
        [ h2 []
            [ text "Hacker News Stories" ]
        , ul [] (List.map hackerNewsStoryView stories)
        ]


hackerNewsStoryView : Story -> Html Msg
hackerNewsStoryView story =
    li []
        [ a [ href story.url ] [ text (story.title ++ " - " ++ (toString story.score)) ]
        ]



---- PROGRAM ----


subscriptions : a -> Sub Msg
subscriptions model =
    Phoenix.connect socket [ channel ]


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
