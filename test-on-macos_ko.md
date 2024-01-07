

## macOS에서 테스트

Racket, fceux 설치 
```
brew install --cask racket
brew install fceux
```

build 빌드 
```
racket co2.scm -o aljazari.nes aljazari/aljazari.co2 
```

실행
```
fceux aljazari.nes
```

## TODO

- [ ] learn Racket, Scheme
- [ ] learn NES architecture
- [ ] learn co2 architecture
- [ ] upgrade co2
- [ ] design games
- [ ] make my own Clojure version
