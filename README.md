# TwoEleven

A [2048](https://play2048.co/) clone using [Elixir](https://elixir-lang.org/)
and [Phoenix](https://phoenixframework.org/).

![Demo Screenshot](https://user-images.githubusercontent.com/23727/170016959-cd4bbcea-c15b-4d2a-90da-e6bcf31f485c.png)

## Highlights

* A game logic based on a lightweight event system. Games are observable and 
  re-playable.

* A multiplayer system build around games. Includes a chat room per game.

* An anonymous account system, which requires no sign ups (although ephemeral).

* The multiplayer core is implemented around
  [DynamicSupervisor](https://hexdocs.pm/elixir/1.13/DynamicSupervisor.html) and
  [Registry](https://hexdocs.pm/elixir/1.13/Registry.html) and
  [Phoenix.Pubsub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html).

* The web side is implemented using
 [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html).
 The project makes use of
 [live sessions](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live_session/3),
 [HEEX language](https://phoenixframework.org/blog/phoenix-1.6-released),
 Phoenix Components, JS contexts and Hooks.

* Styling built with [Tailwind CSS](https://tailwindcss.com/), with a 
  mobile-first design and light/dark themes.

## Getting Started

In order to build and run this project, you need a working *Elixir* environment.
You can also use [Docker](https://www.docker.com/) and avoid any other setup.

The project makes not use of any other runtime dependency (like databases), so
getting it running "should be" straightforward.

### Running with Docker

If you have running [Docker](https://www.docker.com/), getting the project is a
matter of build and running it:

```
docker build . -t two-eleven
docker run -p 8080:8080 two-eleven
```

Make sure your `8080` port is free to use. You can also redirect it to other
port or set `PORT` environment variable to change it.

_Development is also possible inside docker using the `builder` stage_.

### Running with a Elixir

If you have a compatible elixir version running in your system, just run:

```
mix deps.get
iex -S mix phx.server 
```

If you don't have a compatible running elixir version, you can one of these
methods to get one:

  * This project has a [.tool-versions](.tool-versions) file that specifies the
    elixir version required by the project. Use [ASDF](https://asdf-vm.com/) to
    install it.

  * If you use [Nix](https://nixos.org/), this project provides a
    [flake](https://nixos.wiki/wiki/Flakes) with a development shell.

## Improvements and Future Developments

The purpose of this project was to be developed in one weekend, so some ideas,
features and other improvements were left out. These are some of them:

  * _Democracy_ and _anarchy_ game modes.
  * _CI_/_CD_ deployment pipelines using Github Actions.
  * Use `TwoElevenWeb.Presence` to show who is online in a game.
  * Touch and gesture support for mobile gaming.
  * `TwoElevenWeb` tests.
  * Persistence layer.
