#!/bin/sh

set -e

mix deps.get

mix ecto.setup

mix phx.server
