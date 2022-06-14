# Spaceboy

The [Phoenix framework](https://www.phoenixframework.org/) for
[Gemini protocol](https://gemini.circumlunar.space/). Heavily simplified.

## Usage

I recommend you to look at `example/` folder which contains simple application
you can use as starting point.

## Features

- [x] TLS communication
- [x] routing
- [x] custom middleware support
- [x] static files serving
- [x] common response predefined (gemini, json, not found, etc.)
- [-] documentation
  - [-] README
  - [x] in code documentation
  - [-] guides and instructions
- [x] advanced work with client certificates
- [x] telemetry
- [x] templating support
  - [x] Gemini files
  - [x] ANSI files (maybe?)
  - [x] other MIME types?
- [ ] session tracking based on client certificate
- [ ] easy statistics for servers (number of visits, etc.)
- [ ] easy to use testing framework
- [ ] hot code reload

## Contributing

If you have any problem (aka bug) with the code or feature request feel to fill
ticket at <https://todo.sr.ht/~sgiath/spaceboy>. Just don't expect I will
answer or fix the ticket - I have job and family, this is just hobby I do late
at night.

If you have any code you would like to include in the framework feel free to
send me patch at [sgiath@sgiath.dev](mailto:sgiath@sgiath.dev). And again don't
expect I will answer quickly. Please send patches as attachements not in
the email body (you will increase the chance I will be able to apply the patch
easily).

If you want to use part or all of my code and do anything with it - do what the
fuck you want. I don't care - if I would care I wouldn't put it publicly on the
internet.
