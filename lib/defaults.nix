# Central knowledge base: default commands, ports, and packages per ecosystem+framework.
# Values align with what flkr's Go detectors produce.
{
  ecosystems = {
    node = {
      port = 3000;
      buildCommand = "npm run build";
      startCommand = "npm start";
      packageManager = "npm";
      frameworks = {
        nextjs = {
          outputDir = ".next";
        };
        nuxt = {
          outputDir = ".output";
        };
        remix = {
          outputDir = "build";
        };
        vite = {
          outputDir = "dist";
        };
      };
    };

    python = {
      port = 8000;
      buildCommand = null;
      startCommand = null;
      packageManager = "pip";
      frameworks = {
        django = {
          startCommand = "python manage.py runserver 0.0.0.0:8000";
        };
        flask = {
          startCommand = "flask run --host=0.0.0.0";
          port = 5000;
        };
        fastapi = {
          startCommand = "uvicorn main:app --host 0.0.0.0 --port 8000";
        };
      };
    };

    go = {
      port = 8080;
      buildCommand = "go build -o app .";
      startCommand = "./app";
      packageManager = "gomod";
      frameworks = {
        gin = { };
      };
    };

    rust = {
      port = 8080;
      buildCommand = "cargo build --release";
      startCommand = "./target/release/app";
      packageManager = "cargo";
      frameworks = {
        actix = { };
      };
    };

    ruby = {
      port = 3000;
      buildCommand = null;
      startCommand = null;
      packageManager = "bundler";
      frameworks = {
        rails = {
          buildCommand = "bundle exec rake assets:precompile";
          startCommand = "bundle exec rails server -b 0.0.0.0";
        };
      };
    };

    elixir = {
      port = 4000;
      buildCommand = "mix do deps.get, compile";
      startCommand = "mix phx.server";
      packageManager = "mix";
      frameworks = {
        phoenix = {
          systemDeps = [ "inotify-tools" ];
        };
      };
    };

    php = {
      port = 8000;
      buildCommand = null;
      startCommand = null;
      packageManager = "composer";
      frameworks = {
        laravel = {
          buildCommand = "composer install --no-dev --optimize-autoloader";
          startCommand = "php artisan serve --host=0.0.0.0 --port=8000";
          outputDir = "public";
        };
      };
    };

    java = {
      port = 8080;
      buildCommand = null;
      startCommand = null;
      packageManager = "maven";
      packageManagers = {
        maven = {
          buildCommand = "mvn package -DskipTests";
          startCommand = "java -jar target/*.jar";
        };
        gradle = {
          buildCommand = "./gradlew build";
          startCommand = "java -jar build/libs/*.jar";
        };
      };
      frameworks = {
        spring = { };
      };
    };
  };
}
