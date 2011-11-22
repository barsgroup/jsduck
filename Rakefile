require 'rubygems'
require 'rake'
require 'json'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'rspec'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ["--color"]
  spec.pattern = "spec/**/*_spec.rb"
end

def load_sdk_vars
  if File.exists?("sdk-vars.rb")
    require "sdk-vars.rb"
  else
    puts "Error: sdk-vars.rb not found."
    puts
    puts "Please create file sdk-vars.rb and define constants SDK_DIR and OUT_DIR in it."
    puts
    puts "For example:"
    puts
    puts "    # path to Ext JS 4 build"
    puts "    EXT_DIR='/path/to/ext-4.0.7'"
    puts "    # where to output the docs"
    puts "    OUT_DIR='/path/to/ouput/dir'"
    puts "    # path to SDK (for developers at Sencha)"
    puts "    SDK_DIR='/path/to/SDK'"
    puts "    # path to Animator (for developers at Sencha)"
    puts "    ANIMATOR_DIR='/path/to/Animator'"
    exit 1
  end
end

# Compress JS/CSS file in-place
# Using a hackish way to access yui-compressor
def yui_compress(fname)
  system "java -jar $(dirname $(which sencha))/../jsbuilder/ycompressor/ycompressor.jar -o #{fname} #{fname}"
end

# Reads in all CSS files referenced between BEGIN CSS and END CSS markers.
# Deletes those input CSS files and writes out concatenated CSS to
# resources/css/app.css
# Finally replaces the CSS section with <link> to that one CSS file.
def combine_css(html, dir, opts = :write)
  css_section_re = /<!-- BEGIN CSS -->.*<!-- END CSS -->/m
  css = []
  css_section_re.match(html)[0].each_line do |line|
    if line =~ /<link rel="stylesheet" href="(.*?)"/
      file = $1
      css << IO.read(dir + "/" + file)
      system("rm", dir + "/" + file) if opts == :write
    end
  end

  if opts == :write
    fname = "#{dir}/resources/css/app.css"
    File.open(fname, 'w') {|f| f.write(css.join("\n")) }
    yui_compress(fname)
  end
  html.sub(css_section_re, '<link rel="stylesheet" href="resources/css/app.css" type="text/css" />')
end

# Same thing for JavaScript, result is written to: app.js
def combine_js(html, dir)
  js_section_re = /<!-- BEGIN JS -->.*<!-- END JS -->/m
  js = []
  js_section_re.match(html)[0].each_line do |line|
    if line =~ /<script .* src="(.*)">/
      file = $1
      js << IO.read(dir + "/" + file)
      if file !~ /ext\.js/
        system("rm", dir + "/" + file)
      end
    elsif line =~ /<script .*>(.*)<\/script>/
      js << $1
    end
  end

  fname = "#{dir}/app.js"
  File.open(fname, 'w') {|f| f.write(js.join("\n")) }
  yui_compress(fname)
  html.sub(js_section_re, '<script type="text/javascript" src="app.js"></script>')
end

# Compress JavaScript and CSS files of JSDuck
def compress
  load_sdk_vars

  # Clean up template-min/ left over from previous compress task
  system("rm", "-rf", "template-min")
  # Copy template/ files to template-min/
  system("cp", "-r", "template", "template-min")
  # Now do everything that follows in template-min/ dir
  dir = "template-min"

  # Create JSB3 file for Docs app
  system("sencha", "create", "jsb", "-a", "#{dir}/build-js.html", "-p", "#{dir}/app.jsb3")
  # Concatenate files listed in JSB3 file
  system("sencha", "build", "-p", "#{dir}/app.jsb3", "-d", dir)
  # Remove intermediate build files
  system("rm", "#{dir}/app.jsb3")
  system("rm", "#{dir}/all-classes.js")
  # Replace app.js with app-all.js
  system("mv", "#{dir}/app-all.js", "#{dir}/app.js")
  # Remove the entire app/ dir
  system("rm", "-r", "#{dir}/app")

  # Concatenate CSS in print-template.html file
  print_template = "#{dir}/print-template.html";
  html = IO.read(print_template);
  # Just modify HTML to link app.css, don't write files.
  html = combine_css(html, dir, :replace_html_only)
  File.open(print_template, 'w') {|f| f.write(html) }

  # Concatenate CSS and JS files referenced in template.html file
  template_html = "#{dir}/template.html"
  html = IO.read(template_html)
  html = combine_css(html, dir)
  html = combine_js(html, dir)
  File.open(template_html, 'w') {|f| f.write(html) }

  # Clean up SASS files
  # (But keep prettify lib, which is needed for source files)
  system "rm -rf #{dir}/resources/sass"
  system "rm -rf #{dir}/resources/codemirror"
  system "rm -rf #{dir}/resources/.sass-cache"

  # Empty the extjs dir, leave only the main JS files, CSS and images
  system "rm -rf #{dir}/extjs"
  system "mkdir #{dir}/extjs"
  system "cp #{EXT_DIR}/ext-all.js #{dir}/extjs"
  system "cp #{EXT_DIR}/ext-all-debug.js #{dir}/extjs"
  system "cp #{EXT_DIR}/bootstrap.js #{dir}/extjs"
  system "mkdir -p #{dir}/extjs/resources/css"
  system "cp #{EXT_DIR}/resources/css/ext-all.css #{dir}/extjs/resources/css"
  system "mkdir -p #{dir}/extjs/resources/themes/images"
  system "cp -r #{EXT_DIR}/resources/themes/images/default #{dir}/extjs/resources/themes/images"
end


class JsDuckRunner
  def initialize
    @options = []
    load_sdk_vars
    @sdk_dir = SDK_DIR
    @out_dir = OUT_DIR
    @ext_dir = EXT_DIR
    @animator_dir = ANIMATOR_DIR
  end

  def add_options(options)
    @options += options
  end

  def add_sdk
    head_html = <<-EOHTML
      <link rel="canonical" href="http://docs.sencha.com/ext-js/4-0/" />
      <meta name="description" content="Ext JS 4.0 API Documentation from Sencha. Class documentation, Guides and Videos on how to create Javascript applications with Ext JS 4" />
    EOHTML

    @options += [
      "--title", "Sencha Docs - Ext JS 4.0",
      "--head-html", head_html,
      "--footer", "Ext JS 4.0.7 Docs - Generated with <a href='https://github.com/senchalabs/jsduck'>JSDuck</a> rev #{revision}",
      "--welcome", "opt/extjs-welcome.html",
      "--guides", "#{@sdk_dir}/extjs/docs/guides.json",
      "--videos", "#{@sdk_dir}/extjs/docs/videos.json",
      "--examples", "#{@sdk_dir}/extjs/examples/examples.json",
      "--categories", "#{@sdk_dir}/extjs/docs/categories.json",
      "--local-storage-db", "ext-4",
      "--output", "#{@out_dir}",
      "--builtin-classes",
      "--images", "#{@sdk_dir}/extjs/docs/resources",
      "--images", "#{@sdk_dir}/platform/docs/resources",
      "--stats",
      "#{@sdk_dir}/extjs/src",
      "#{@sdk_dir}/platform/src",
      "#{@sdk_dir}/platform/core/src",
      "#{@sdk_dir}/extjs/examples/ux",
    ]
  end

  def add_relative_examples_path
    @options += ["--head-html", <<-EOHTML]
      <script type="text/javascript">
        Docs.exampleBaseUrl = "#{relative_sdk_path}examples/";
      </script>
    EOHTML
  end

  # Enables comments when CORS is supported by browser.
  # This excludes Opera and IE < 8
  def add_comments(db_name)
    comments_base_url = "http://projects.sencha.com/auth"
    @options += ["--head-html", <<-EOHTML]
      <script type="text/javascript">
        Docs.enableComments = ("withCredentials" in new XMLHttpRequest()) || (typeof XDomainRequest !== "undefined");
        Docs.baseUrl = "#{comments_base_url}";
        Docs.commentsDb = "#{db_name}";
      </script>
    EOHTML
  end

  # For export of ExtJS, reference extjs from the parent dir
  def make_paths_relative
    relative_sdk_path = "../"
    ["#{@out_dir}/eg-iframe.html", "#{@out_dir}/index.html"].each do |file|
      out = []
      IO.read(file).each_line do |line|
        out << line.sub(/((src|href)="extjs\/)/, '\2="' + relative_sdk_path)
      end
      File.open(file, 'w') {|f| f.write(out) }
    end
  end

  def add_ext3
    head_html = <<-EOHTML
      <link rel="canonical" href="http://docs.sencha.com/ext-js/3-4/" />
      <meta name="description" content="Ext JS 3.4 API Documentation from Sencha. Class documentation, Guides and Videos on how to create Javascript applications with Ext JS 3.4" />
    EOHTML

    @options += [
      "--title", "Sencha Docs - Ext JS 3.4",
      "--footer", "Ext JS 3.4 Docs - Generated with <a href='https://github.com/senchalabs/jsduck'>JSDuck</a> revison #{revision}",
      "--categories", "#{@sdk_dir}/../ext-3.4.0/src/categories.json",
      "--ignore-global",
      "--local-storage-db", "ext-3",
      "--output", "#{@out_dir}",
      "#{@sdk_dir}/../ext-3.4.0/src/core",
      "#{@sdk_dir}/../ext-3.4.0/src/data",
      "#{@sdk_dir}/../ext-3.4.0/src/dd",
      "#{@sdk_dir}/../ext-3.4.0/src/direct",
      "#{@sdk_dir}/../ext-3.4.0/src/ext-core/src",
      "#{@sdk_dir}/../ext-3.4.0/src/state",
      "#{@sdk_dir}/../ext-3.4.0/src/util",
      "#{@sdk_dir}/../ext-3.4.0/src/widgets"
    ]
  end

  def add_ext4
    @options += [
      "--title", "Sencha Docs - Ext JS 4.0",
      "--footer", "Ext JS 4.0 Docs - Generated with <a href='https://github.com/senchalabs/jsduck'>JSDuck</a> revison #{revision}",
      "--ignore-global",
      "--no-warnings",
      "--images", "#{@ext_dir}/docs/doc-resources",
      "--local-storage-db", "ext-4",
      "--output", "#{@out_dir}",
      "#{@ext_dir}/src",
    ]
  end

  def add_touch
    head_html = <<-EOHTML
      <link rel="canonical" href="http://docs.sencha.com/touch/1-1/" />
      <meta name="description" content="Sencha Touch 1.1 API Documentation from Sencha. Documentation on how to create Javascript applications with Sencha Touch" />
    EOHTML

    @options += [
      "--title", "Sencha Docs - Touch 1.1",
      "--head-html", head_html,
      "--footer", "Sencha Touch 1.1 Docs - Generated with <a href='https://github.com/senchalabs/jsduck'>JSDuck</a> revison #{revision}",
      "--categories", "#{@sdk_dir}/touch/doc-resources/categories.json",
      "--videos", "#{@sdk_dir}/touch/doc-resources/videos.json",
      "--local-storage-db", "touch-1",
      "--output", "#{@out_dir}",
      "--external=google.maps.Map,google.maps.LatLng",
      "--images", "#{@sdk_dir}/touch/doc-resources",
      "#{@sdk_dir}/touch/resources/themes/stylesheets/sencha-touch/default",
    ]

    @options += extract_jsb_build_files("#{@sdk_dir}/touch/sencha-touch.jsb3")
  end

  def add_touch2
    head_html = <<-EOHTML
      <link rel="canonical" href="http://docs.sencha.com/touch/2-0/" />
      <meta name="description" content="Sencha Touch 2.0 API Documentation from Sencha. Documentation on how to create Javascript applications with Sencha Touch" />
    EOHTML

    @options += [
      "--title", "Sencha Docs - Touch 2.0",
      "--head-html", head_html,
      "--footer", "Sencha Touch 2.0 Docs - Generated with <a href='https://github.com/senchalabs/jsduck'>JSDuck</a> revison #{revision}",
      "--categories", "#{@sdk_dir}/touch/docs/categories.json",
      "--welcome", "opt/touch-welcome.html",
      "--videos", "#{@sdk_dir}/touch/docs/videos.json",
      "--guides", "#{@sdk_dir}/touch/docs/guides.json",
      "--examples", "#{@sdk_dir}/touch/docs/examples.json",
      "--touch-examples-ui",
      "--local-storage-db", "touch-2",
      "--output", "#{@out_dir}",
      "--external=google.maps.Map,google.maps.LatLng",
      "--builtin-classes",
      "--img", "<p class='screenshot'><img src='%u' alt='%a'><span>%a</span></p>",
      "--eg-iframe", "opt/touch-iframe.html",
      "--warnings=-image",
      # "--stats",
      "#{@sdk_dir}/touch/resources/themes/stylesheets/sencha-touch/default",
    ]

    @options += extract_jsb_build_files("#{@sdk_dir}/touch/touch.jsb3")
  end

  def add_touch_export
    @options += [
      "--json",
      "--output", "#{@out_dir}/../export/touch1",
      "--external=google.maps.Map,google.maps.LatLng",
    ]
    @options += extract_jsb_build_files("#{@sdk_dir}/touch/sencha-touch.jsb3")
  end

  def add_touch2_export
    @options += [
      "--json",
      "--output", "#{@out_dir}/../export/touch2",
      "--external=google.maps.Map,google.maps.LatLng",
    ]
    @options += extract_jsb_build_files("#{@sdk_dir}/touch/touch.jsb3")
  end

  def set_touch2_src
    relative_touch_path = "../"
    system("cp", "-r", "opt/touch-welcome.html", "template-min/touch-welcome.html")
    system("cp", "-r", "opt/touch-iframe.html", "template-min/touch-iframe.html")

    ["template-min/touch-iframe.html", "template-min/touch-welcome.html"].each do |file|
      html = IO.read(file);

      touch_src_re = /((src|href)="touch)/m
      out = []

      html.each_line do |line|
        out << line.sub(/((src|href)="touch\/)/, '\2="' + relative_touch_path)
      end

      File.open(file, 'w') {|f| f.write(out) }
    end

    head_html = <<-EOHTML
      <script type="text/javascript">
        Docs.exampleBaseUrl = "#{relative_touch_path}examples/";
        if (Ext.is.Phone) { window.location = "#{relative_touch_path}examples/"; }
      </script>
    EOHTML

    @options += [
      "--body-html", head_html,
      "--welcome", "template-min/touch-welcome.html",
      "--eg-iframe", "template-min/touch-iframe.html"
    ]
  end

  def add_touch_charts
    head_html = <<-EOHTML
      <link rel="canonical" href="http://docs.sencha.com/touch-charts/1-0/" />
      <meta name="description" content="Sencha Touch Charts 1.0 API Documentation. Documentation on how to create Charts with Sencha Touch" />
    EOHTML

    @options += [
      "--title", "Sencha Docs - Touch Charts 1.0",
      "--head-html", head_html,
      "--footer", "Sencha Touch Charts 1.0 Docs - Generated with <a href='https://github.com/senchalabs/jsduck'>JSDuck</a>",
      "--categories", "#{@sdk_dir}/charts/docs/categories.json",
      "--guides", "#{@sdk_dir}/charts/docs/guides.json",
      "--images", "#{@sdk_dir}/charts/docs/resources",
      "--local-storage-db", "touch-charts",
      "--output", "#{@out_dir}"
    ]

    @options += extract_jsb_build_files("#{@sdk_dir}/charts/touch-charts.jsb3")
  end

  def add_sencha_io
    head_html = <<-EOHTML
      <link rel="canonical" href="http://docs.sencha.com/sencha-io/1-0/" />
      <meta name="description" content="Sencha.io 1.0 API Documentation. Documentation on how to use the Sencha.io SDK" />
    EOHTML

    @options += [
      "--title", "Sencha Docs - IO 1.0",
      "--head-html", head_html,
      "--footer", "Sencha.io 1.0 Docs - Generated with <a href='https://github.com/senchalabs/jsduck'>JSDuck</a>",
      "--guides", "#{@sdk_dir}/../sync/docs/guides.json",
      "--images", "#{@sdk_dir}/../sync/docs/resources",
      "--local-storage-db", "sencha-io",
      "--ignore-global",
      "--output", "#{@out_dir}"
    ]

    @options += extract_jsb_build_files("#{@sdk_dir}/../sync/sencha-io.jsb3")
  end

  def add_animator
    head_html = <<-EOHTML
      <link rel="canonical" href="http://docs.sencha.com/animator/1-0/" />
      <meta name="description" content="Sencha Animator 1.0 API Documentation from Sencha. Documentation on how to create Javascript applications with Sencha Touch" />
    EOHTML

    @options += [
      "--title", "Sencha Docs - Animator 1.0",
      "--head-html", head_html,
      "--footer", "Sencha Animator 1.0 Docs - Generated with <a href='https://github.com/senchalabs/jsduck'>JSDuck</a> revison #{revision}",
      # "--videos", "#{@animator_dir}/docs/videos.json",
      "--guides", "#{@animator_dir}/docs/guides.json",
      # "--examples", "#{@animator_dir}/docs/examples/examples.json",
      "--local-storage-db", "animator",
      "--output", "#{@out_dir}",
    ]
  end

  # Extracts files of first build in jsb file
  def extract_jsb_build_files(jsb_file)
    json = JSON.parse(IO.read(jsb_file))
    basedir = File.dirname(jsb_file)

    return json["builds"][0]["packages"].map do |package_id|
      package = json["packages"].find {|p| p["id"] == package_id }
      package["files"].map do |file|
        basedir + "/" + file["path"] + file["name"]
      end
    end.flatten
  end

  # Returns shortened hash of naming current git revision
  def revision
    `git rev-parse HEAD`.slice(0, 7)
  end

  def add_debug
    @options += [
      "--extjs-path", "extjs/ext-all-debug.js",
      "--template-links",
      "--template", "template",
    ]
  end

  def add_seo
    @options += [
      "--seo",
    ]
  end

  def add_sdk_export_notice
    @options += [
      "--body-html", <<-EOHTML
      <div id="notice-text" style="display: none">
        Use <a href="http://docs.sencha.com/ext-js/4-0">http://docs.sencha.com/ext-js/4-0</a> for up to date documentation and features
      </div>
      EOHTML
    ]
  end

  def add_touch2_export_notice
    @options += [
      "--body-html", <<-EOHTML
      <div id="notice-text" style="display: none">
        Use <a href="http://docs.sencha.com/touch/2-0">http://docs.sencha.com/touch/2-0</a> for up to date documentation and features
      </div>
      EOHTML
    ]
  end

  def add_google_analytics
    @options += [
      "--body-html", <<-EOHTML
      <script type="text/javascript">
        var _gaq = _gaq || [];
        _gaq.push(['_setAccount', 'UA-1396058-10']);
        _gaq.push(['_trackPageview']);
        (function() {
          var ga = document.createElement('script');
          ga.type = 'text/javascript';
          ga.async = true;
          ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
          var s = document.getElementsByTagName('script')[0];
          s.parentNode.insertBefore(ga, s);
        })();

        Docs.initEventTracking = function() {
            Docs.App.getController('Classes').addListener({
                showClass: function(cls) {
                    _gaq.push(['_trackEvent', 'Classes', 'Show', cls]);
                },
                showMember: function(cls, anchor) {
                    _gaq.push(['_trackEvent', 'Classes', 'Member', cls + ' - ' + anchor]);
                }
            });
            Docs.App.getController('Guides').addListener({
                showGuide: function(guide) {
                    _gaq.push(['_trackEvent', 'Guides', 'Show', guide]);
                }
            });
            Docs.App.getController('Videos').addListener({
                showVideo: function(video) {
                    _gaq.push(['_trackEvent', 'Video', 'Show', video]);
                }
            });
            Docs.App.getController('Examples').addListener({
                showExample: function(example) {
                    _gaq.push(['_trackEvent', 'Example', 'Show', example]);
                }
            });
        }

        Docs.otherProducts = [
          {
              text: 'Ext JS 4',
              href: 'http://docs.sencha.com/ext-js/4-0'
          },
          {
              text: 'Ext JS 3',
              href: 'http://docs.sencha.com/ext-js/3-4'
          },
          {
              text: 'Sencha Touch 2',
              href: 'http://docs.sencha.com/touch/2-0'
          },
          {
              text: 'Sencha Touch 1',
              href: 'http://docs.sencha.com/touch/1-1'
          },
          {
              text: 'Touch Charts',
              href: 'http://docs.sencha.com/touch-charts/1-0'
          },
          {
              text: 'Sencha Animator',
              href: 'http://docs.sencha.com/animator/1-0'
          }
        ];
      </script>
    EOHTML
    ]

  end

  # Copy over SDK examples
  def copy_sdk_examples
    system "mkdir #{@out_dir}/extjs/builds"
    system "cp #{@ext_dir}/builds/ext-core.js #{@out_dir}/extjs/builds/ext-core.js"
    system "cp #{@ext_dir}/release-notes.html #{@out_dir}/extjs"
    system "cp -r #{@ext_dir}/examples #{@out_dir}/extjs"
    system "cp -r #{@ext_dir}/welcome #{@out_dir}/extjs"
  end

  def copy_animator_examples
    system "mkdir -p #{@out_dir}/extjs"
    system "cp -r #{@animator_dir}/docs/examples #{@out_dir}/extjs"
  end

  # Copy over Sencha Touch
  def copy_touch2_build
    system "cp -r #{@sdk_dir}/touch/build #{@out_dir}/touch"
  end

  def run
    # Pass multiple arguments to system, so we'll take advantage of the built-in escaping
    system(*["ruby", "bin/jsduck"].concat(@options))
  end
end

# Run compass to generate CSS files
task :sass do
  system "compass compile --quiet template/resources/sass"
end

desc "Updates JSB3 file for Docs app.\n"+
     "Run this before every commit that changes JS dependencies."
task :jsb do
  system("sencha", "create", "jsb", "-a", "template/build-js.html", "-p", "template/app.jsb3")
end

desc "Run JSDuck on Ext JS SDK (for internal use at Sencha)\n" +
     "sdk         - creates debug/development version\n" +
     "sdk[export] - creates export version\n" +
     "sdk[live]   - create live version for deployment\n"
task :sdk, [:mode] => :sass do |t, args|
  mode = args[:mode] || "debug"
  throw "Unknown mode #{mode}" unless ["debug", "export", "live"].include?(mode)
  compress if mode == "export" || mode == "live"

  runner = JsDuckRunner.new
  runner.add_sdk
  runner.add_debug if mode == "debug"
  runner.add_seo if mode == "debug" || mode == "live"
  runner.add_sdk_export_notice if mode == "export"
  runner.add_google_analytics if mode == "live"
  runner.add_comments('comments-ext-js-4') if mode == "debug" || mode == "live"
  runner.run

  runner.copy_sdk_examples if mode == "export" || mode == "live"
  runner.make_paths_relative if mode == "export"
end

desc "Run JSDuck on Docs app itself"
task :docs do
  runner = JsDuckRunner.new
  runner.add_ext4
  runner.add_options([
    "--builtin-classes",
    "template/app"
  ])
  runner.add_debug
  runner.add_seo
  runner.run
end

desc "Run JSDuck on official Ext JS 4.0.2a build\n" +
     "ext4             - creates debug/development version\n" +
     "ext4[export]     - creates export/deployable version\n"
task :ext4, [:mode] => :sass do |t, args|
  mode = args[:mode] || "debug"
  throw "Unknown mode #{mode}" unless ["debug", "export"].include?(mode)
  compress if mode == "export"

  runner = JsDuckRunner.new
  runner.add_ext4
  runner.add_debug if mode == "debug"
  runner.add_seo
  runner.run
end

desc "Run JSDuck on official Ext JS 3.4 build\n" +
     "ext3             - creates debug/development version\n" +
     "ext3[export]     - creates export/deployable version\n"
     "ext3[live]       - creates live version for deployment\n"
task :ext3, [:mode] => :sass do |t, args|
  mode = args[:mode] || "debug"
  throw "Unknown mode #{mode}" unless ["debug", "export", "live"].include?(mode)
  compress if mode == "export"

  runner = JsDuckRunner.new
  runner.add_ext3
  runner.add_debug if mode == "debug"
  runner.add_seo if mode == "live"
  runner.add_google_analytics if mode == "live"
  runner.run
end

desc "Run JSDuck on Sencha Touch (for internal use at Sencha)\n" +
     "touch       - creates debug/development version\n" +
     "touch[live] - create live version for deployment\n"
task :touch, [:mode] => :sass do |t, args|
  mode = args[:mode] || "debug"
  throw "Unknown mode #{mode}" unless ["debug", "live"].include?(mode)
  compress if mode == "live"

  runner = JsDuckRunner.new
  runner.add_touch
  runner.add_debug if mode == "debug"
  runner.add_seo if mode == "debug" || mode == "live"
  runner.add_google_analytics if mode == "live"
  runner.run
end

desc "Run JSDuck on Sencha Touch 2 (for internal use at Sencha)\n" +
     "touch2         - creates debug/development version\n" +
     "touch2[export] - creates export version\n" +
     "touch2[live]   - create live version for deployment\n"
task :touch2, [:mode] => :sass do |t, args|
  mode = args[:mode] || "debug"
  throw "Unknown mode #{mode}" unless ["debug", "export", "live"].include?(mode)
  compress if mode == "live" || mode == "export"

  runner = JsDuckRunner.new
  runner.add_touch2
  runner.add_debug if mode == "debug"
  runner.add_touch2_export_notice if mode == "export"
  runner.set_touch2_src if mode == "export"
  runner.add_seo if mode == "debug" || mode == "live"
  runner.add_google_analytics if mode == "live"
  runner.add_comments('comments-touch-2') if mode == "debug" || mode == "live"
  runner.run

  runner.copy_touch2_build if mode != "export"
end

desc "Run JSDuck on Sencha Touch Charts (for internal use at Sencha)\n" +
     "charts         - creates debug/development version\n" +
     "charts[export] - create live version for deployment\n"
     "charts[live]   - create live version for deployment\n"
task :charts, [:mode] => :sass do |t, args|
  mode = args[:mode] || "debug"
  throw "Unknown mode #{mode}" unless ["debug", "export", "live"].include?(mode)
  compress if mode == "live"

  runner = JsDuckRunner.new
  runner.add_touch_charts
  runner.add_debug if mode == "debug"
  runner.add_seo if mode == "debug" || mode == "live"
  runner.add_google_analytics if mode == "live"
  runner.run
end

desc "Run JSDuck on Sencha.IO Sync (for internal use at Sencha)\n" +
     "senchaio         - creates debug/development version\n" +
     "senchaio[export] - create live version for deployment\n"
     "senchaio[live]   - create live version for deployment\n"
task :senchaio, [:mode] => :sass do |t, args|
  mode = args[:mode] || "debug"
  throw "Unknown mode #{mode}" unless ["debug", "export", "live"].include?(mode)
  compress if mode == "live"

  runner = JsDuckRunner.new
  runner.add_sencha_io
  runner.add_debug if mode == "debug"
  runner.add_seo if mode == "debug" || mode == "live"
  runner.add_google_analytics if mode == "live"
  runner.run
end

desc "Run JSDuck JSON Export (for internal use at Sencha)\n" +
     "export[touch]  - creates export for Touch 1\n" +
     "export[touch2] - creates export for Touch 2"
task :export, [:mode] do |t, args|
  mode = args[:mode]
  throw "Unknown mode #{mode}" unless ["touch", "touch2"].include?(mode)

  runner = JsDuckRunner.new
  runner.add_touch_export if mode == "touch"
  runner.add_touch2_export if mode == "touch2"
  runner.run
end

desc "Run JSDuck on Sencha Animator (for internal use at Sencha)\n" +
     "animator         - creates debug/development version\n" +
     "animator[export] - create live version for deployment\n"
     "animator[live]   - create live version for deployment\n"
task :animator, [:mode] => :sass do |t, args|
  mode = args[:mode] || "debug"
  throw "Unknown mode #{mode}" unless ["debug", "live", "export"].include?(mode)
  compress if mode == "live"

  runner = JsDuckRunner.new
  runner.add_animator
  runner.add_debug if mode == "debug"
  runner.add_seo if mode == "debug" || mode == "live"
  runner.add_google_analytics if mode == "live"
  runner.run

  runner.copy_animator_examples
end

desc "Build JSDuck gem"
task :gem => :sass do
  compress
  system "gem build jsduck.gemspec"
end

task :default => :spec
