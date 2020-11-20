# Changelog

## 2.3.0 - 2019-11-03
### Added
- Code Format

### Changed
- Change mock to mimic
- Fixed dialyzer
- Deprecated elixir version > 1.8

## 2.2.2 - 2017-09-06
### Added
- Fixed type specs of conn.ex, added type spec for error.ex

## 2.2.1 - 2017-05-12
### Added
- Add [Conn.put_private/3 and Conn.get_private/2](https://github.com/zhongwencool/maxwell/pull/57)
- Allow query strings to have nested params and arrays(https://github.com/zhongwencool/maxwell/pull/55).
- Add fixed header override

### Changed
-  Using System.monotonic_time() to [show cost time](https://github.com/zhongwencool/maxwell/pull/48).
-  Improve a collection of [general API](https://github.com/zhongwencool/maxwell/pull/36).
-  [Refine multipart](https://github.com/zhongwencool/maxwell/pull/61)

## 2.2.0 - 2017-02-14
### Added
- Add retry middleware
- Add fuse middleware
- Add header base middleware

### Changed
-  Setting log_level [by status code in Logger Middleware](https://github.com/zhongwencool/maxwell/pull/45).
-  Improve a collection of [general API](https://github.com/zhongwencool/maxwell/pull/36).
-  Improve [the BaseUrl middleware](https://github.com/zhongwencool/maxwell/pull/38)
-  Fixed warning by elixir v1.4.0.
-  Support poison ~> 3.0.
-  Numerous document updates.

## 2.1.0 - 2016-12-19
### Added
- Support httpc adapter.

### Changed
- Rewrite adapter's test case by `mock`. coverage == 100%


## 2.0.0 - 2016-12-08
### Changed
- Restruct `Maxwell.conn`.
- Rewrite `put_*` and `get_*` helper function.
- Support send stream.
- Support send file.
