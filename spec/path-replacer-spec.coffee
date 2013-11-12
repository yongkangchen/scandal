fs = require 'fs'
os = require 'os'
path = require 'path'
PathReplacer = require '../src/path-replacer'

describe "PathReplacer", ->
  [replacer, rootPath] = []

  beforeEach ->
    replacer = new PathReplacer()
    rootPath = fs.realpathSync("spec/fixtures/many-files")

  describe "replacePaths()", ->
    [filePath, sampleContent] = []

    beforeEach ->
      filePath = path.join(rootPath, 'sample.js')
      sampleContent = fs.readFileSync(filePath).toString()

    afterEach ->
      fs.writeFileSync(filePath, sampleContent)

    it "can make a replacement", ->
      replacer.on('path-replaced', resultsHandler = jasmine.createSpy())
      replacer.replacePaths(/items/gi, 'omgwow', [filePath], finishedHandler = jasmine.createSpy())

      waitsFor ->
        finishedHandler.callCount > 0

      runs ->
        expect(resultsHandler).toHaveBeenCalled()
        expect(resultsHandler.mostRecentCall.args[0]).toEqual
          filePath: filePath
          replacements: 6

        replacedFile = fs.readFileSync(filePath).toString()

        replacedContent = '''
          var quicksort = function () {
            var sort = function(omgwow) {
              if (omgwow.length <= 1) return omgwow;
              var pivot = omgwow.shift(), current, left = [], right = [];
              while(omgwow.length > 0) {
                current = omgwow.shift();
                current < pivot ? left.push(current) : right.push(current);
              }
              return sort(left).concat(pivot).concat(sort(right));
            };

            return sort(Array.apply(this, arguments));
          };
        '''.replace(/\n/g, os.EOL)
        expect(replacedFile).toEqual replacedContent

    it "makes no replacement when nothing to replace", ->
      replacer.on('path-replaced', resultsHandler = jasmine.createSpy())
      replacer.replacePaths(/nopenothere/gi, 'omgwow', [filePath], finishedHandler = jasmine.createSpy())

      waitsFor ->
        finishedHandler.callCount > 0

      runs ->
        expect(resultsHandler).not.toHaveBeenCalled()
        replacedFile = fs.readFileSync(filePath).toString()
        expect(replacedFile).toEqual sampleContent
