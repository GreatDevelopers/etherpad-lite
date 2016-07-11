@0x93020f652e8a8459;

using Spk = import "/sandstorm/package.capnp";
# This imports:
#   $SANDSTORM_HOME/latest/usr/include/sandstorm/package.capnp
# Check out that file to see the full, documented package definition format.

const pkgdef :Spk.PackageDefinition = (
  # The package definition. Note that the spk tool looks specifically for the
  # "pkgdef" constant.

  id = "h37dm17aa89yrd8zuqpdn36p6zntumtv08fjpu8a8zrte7q1cn60",
  # Your app ID is actually its public key. The private key was placed in
  # your keyring. All updates must be signed with the same key.

  manifest = (
    # This manifest is included in your app package to tell Sandstorm
    # about your app.

    appTitle = (defaultText = "Etherpad"),

    appVersion = 14,  # Increment this for every release.
    
    appMarketingVersion = (defaultText = "1.6.0"),

    actions = [
      # Define your "new document" handlers here.
      ( title = (defaultText = "New Etherpad Document"),
        nounPhrase = (defaultText = "pad"),
        command = .myCommand
        # The command to run when starting for the first time. (".myCommand"
        # is just a constant defined at the bottom of the file.)
      )
    ],

    continueCommand = .myCommand,
    # This is the command called to start your app back up after it has been
    # shut down for inactivity. Here we're using the same command as for
    # starting a new instance, but you could use different commands for each
    # case.

    metadata = (
      icons = (
        appGrid = (svg = embed "app-graphics/etherpad-128.svg"),
        grain = (svg = embed "app-graphics/etherpad-24.svg"),
        market = (svg = embed "app-graphics/etherpad-150.svg"),
      ),

      website = "http://etherpad.org/",
      codeUrl = "https://github.com/kentonv/etherpad-lite",
      license = (openSource = apache2),
      categories = [office, productivity],

      author = (
        contactEmail = "kenton@sandstorm.io",
        pgpSignature = embed "pgp-signature",
        upstreamAuthor = "Etherpad Foundation",
      ),
      pgpKeyring = embed "pgp-keyring",

      description = (defaultText = embed "description.md"),
      shortDescription = (defaultText = "Document editor"),

      screenshots = [
        (width = 448, height = 343, png = embed "sandstorm-screenshot.png")
      ],

      changeLog = (defaultText = embed "CHANGELOG.md"),
    ),
  ),

  sourceMap = (
    # Here we defined where to look for files to copy into your package. The
    # `spk dev` command actually figures out what files your app needs
    # automatically by running it on a FUSE filesystem. So, the mappings
    # here are only to tell it where to find files that the app wants.
    searchPath = [
      ( sourcePath = "." ),  # Search this directory first.
      ( sourcePath = "/",    # Then search the system root directory.
        hidePaths = [ "home", "proc", "sys" ]
        # You probably don't want the app pulling files from these places,
        # so we hide them. Note that /dev, /var, and /tmp are implicitly
        # hidden because Sandstorm itself provides them.
      ),
      ( sourcePath = "/opt/sandstorm/latest/usr/include",
        packagePath = "usr/include" )
    ]
  ),

  fileList = "sandstorm-files.list",
  # `spk dev` will write a list of all the files your app uses to this file.
  # You should review it later, before shipping your app.

  alwaysInclude = ["src", "node_modules"],
  # Fill this list with more names of files or directories that should be
  # included in your package, even if not listed in sandstorm-files.list.
  # Use this to force-include stuff that you know you need but which may
  # not have been detected as a dependency during `spk dev`. If you list
  # a directory here, its entire contents will be included recursively.

  bridgeConfig = (
    viewInfo = (
      permissions = [(name = "modify", title = (defaultText = "modify"),
                      description = (defaultText = "allows modifying the document")),
                     (name = "comment", title = (defaultText = "comment"),
                      description = (defaultText = "allows adding comments"))],
      roles = [(title = (defaultText = "editor"),
                permissions = [true, true],
                verbPhrase = (defaultText = "can edit"),
                default = true),
               (title = (defaultText = "viewer"),
                permissions = [false, false],
                verbPhrase = (defaultText = "can view")),
               (title = (defaultText = "commenter"),
                permissions = [false, true],
                verbPhrase = (defaultText = "can comment"))],
      eventTypes = [
        (name = "edit", verbPhrase = (defaultText = "edited pad"),
            notifySubscribers = false, autoSubscribeToGrain = true),
        (name = "comment", verbPhrase = (defaultText = "added comment"),
            notifySubscribers = true, autoSubscribeToThread = true),
        (name = "reply", verbPhrase = (defaultText = "replied to comment"),
            notifySubscribers = true, autoSubscribeToThread = true)
      ],
    ),

    saveIdentityCaps = true,
  )
);

const myCommand :Spk.Manifest.Command = (
  # Here we define the command used to start up your server.
  argv = ["/sandstorm-http-bridge", "9001", "--", "bin/run.sh"],
  environ = [
    # Note that this defines the *entire* environment seen by your app.
    (key = "PATH", value = "/usr/local/bin:/usr/bin:/bin")
  ]
);
