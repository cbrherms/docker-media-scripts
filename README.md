  # Dockerised Media-Scripts

  ## Overview

  This **Docker-Media-Scripts** container is designed to simplify the execution of [chazlarson/Media-Scripts](https://github.com/chazlarson/Media-Scripts) within a Docker environment.

  ## Why?

  - **GitHub Updates**: Automatically fetches the latest version of [chazlarson/Media-Scripts](https://github.com/chazlarson/Media-Scripts).
  - **Easy Script Execution**: Execute any of the downloaded scripts by specifying its filename.
  - **Optimized for Unraid OS**: Originally created with Unraid OS in mind, but should be adaptable to any platform with Docker or Docker Compose.

  ## Prerequisites

  Depending on your environment:

  1. **Unraid OS (Recommended)**:
      - Unraid OS installed and configured.
      - A location within Unraid to store your scripts (e.g. a folder within your appdata share).
      - For the easiest setup, consider using the **Docker Compose Manager** plugin. Ibracorp has a useful guide for this on their [docs site](https://docs.ibracorp.io/docker-compose/docker-compose-for-unraid)
      - The **User Scripts** plugin if you wish to schedule these script runs.


  2. **Other Operating Systems**:
      - Docker installed on your system.
      - Optionally, install Docker Compose if you plan to use it.
      - Note that if you're running a non-Linux-based OS, you may need to adjust file paths accordingly.

  ## Creating The Docker Container

  ### Using Docker Compose:

  ```yaml
  version: "3.8"
  services:
    media-scripts:
      image: ghcr.io/cbrherms/docker-media-scripts:latest
      container_name: docker-media-scripts
      environment:
        - PUID=99
        - PGID=100
        - TZ=Europe/London
      volumes:
        - /path/to/appdata/docker-media-scripts:/config 
        - /path/to/appdata/plex-meta-manager/assets:/assets # optional - case sensitive
  ```


  ### Using Docker Run:

  ```bash
  docker run \
    -e PUID=99 \
    -e PGID=100 \
    -e TZ=Europe/London \
    -v /path/to/appdata/docker-media-scripts:/config \
    -v /path/to/appdata/plex-meta-manager/assets:/assets \
    ghcr.io/cbrherms/docker-media-scripts:latest
  ```

  ### Notes:

  1. **Mounting Folders**:
      - Make sure to mount the folder where you want the scripts to be downloaded to inside the container, as well as any additional folders such as your PMM assets location.
      - For instance, on my system, I have these directories on my cache disk under the appdata share:
          ```yaml
          volumes:
            - /mnt/user/appdata/docker-media-scripts:/config 
            - /mnt/user/appdata/plex-meta-manager/assets:/assets
          ```
      - Pay attention to the path for PMM (Plex Meta Manager). If you use the official image template, it has capital letters in the default folder path.

  2. **Ownership and Permissions**:
      - Upon container start, the folder mounted to `/config` will recursively have its owner and group set to `dockeruser` after the media-scripts repository is either downloaded or updated.

  ## Additional Configuration

  ### Environment Variables:

  - `PUID`- Default `99` - User ID given to the containers internal `dockeruser`
  - `PGID`- Default `100` - Group ID given to the containers internal `dockeruser`
  - `CONFIG_DIR` - Default `/config` - Location media-scripts repo will be created/updated
  - `UMASK` - Default `002` - Octal Umask to specify the permissions of files created by scripts in this container. These are subtractive from `777`. Further info on Umask can be found [here](https://en.wikipedia.org/wiki/Umask).


  ### Media-Scripts .env Tweaks:

  1. **Adjusting `ASSET_DIR`**:
      - The `ASSET_DIR` variable in your `.env` file needs to be set to a full path. This path should correspond to the location where you've mounted the folder inside your container.
      - For instance, based on the examples provided earlier, you would set `ASSET_DIR=/assets`.

  2. **Working Directory for `.env`**:
      - Note that the `.env` file is only read from the working directory where the script is executed.
      - To address this, consider creating your `.env` file in your main media-scripts folder. Then, hardlink it into each of the subfolders (e.g., Plex, Plex Meta Manager, TMDB, etc.). This must be done on your host, not within the container.
      - Here's an example using the Unraid CLI:
          ```bash
          # Create a hardlink from the source folder to the destination folder
          ln /mnt/user/appdata/docker-media-scripts/.env /mnt/user/appdata/docker-media-scripts/Plex/.env
          ```
      - By doing this, you'll only need to edit the `.env` file in one place, and the changes will propagate to all relevant subfolders.

  ## Usage

  ### Executing Scripts Within the Container

  Once you have the container up and running, you can execute a script from your host machine using the following command:

  ```bash
  docker exec container_name runscript script-name.py
  ```

  Here's what happens when you run this command:

  1. The `runscript` command searches for the specified `script-name.py` within the `/config` folder (which you've mounted inside the container).
  2. It sets the working directory path correctly to ensure the script runs smoothly and that logs and such created by the script are created in the correct place for future reference.
  3. The script is executed with the `PGID`, `PUID`, and `UMASK` set in the container's environment variables.
  4. Any output generated by the script will be redirected to the Docker log.

  You don't need to provide the full path to the script; the `runscript` command will automatically find it within the configured folder.

  For example, if you're using a container created with the provided Docker Compose or Docker Run commands, you can execute a script like this:

  ```bash
  docker exec docker-media-scripts runscript grab-all-posters.py
  ```

  ## Scheduling Scripts

  ### Using User Scripts Plugin (Unraid)

  If you're using Unraid, the **User Scripts** plugin provides an easy way to schedule script execution. Follow these steps:

  1. **Install User Scripts Plugin**:
      - If you haven't already, install the **User Scripts** plugin from the Unraid Community Applications.
      - Go to the Unraid web interface, navigate to **Apps**, search for "User Scripts," and install it.

  2. **Create a New User Script**:
      - Open the **User Scripts** plugin.
      - Click on **Add New Script**.
      - Give your script a name.
      - In the **Script** section, enter the following command (adjust the script name as needed):
          ```bash
          docker exec docker-media-scripts runscript script-name.py
          ```
      - Save the script.

  3. **Schedule Execution**:
      - Set the desired schedule for your script (e.g., daily, weekly, custom cron expression etc.).
      - Save the settings.

  4. **Run the Script**:
      - The User Scripts plugin will automatically execute your script according to the schedule you've set.

  ### Using Cron (Linux/MacOS)

  On other systems  (Linux, macOS, etc.), you may use the `cron` scheduler to automate script execution:

  1. **Edit Your Crontab**:
      - Open your terminal or shell.
      - Type `crontab -e` to edit your user's crontab.

  2. **Add a New Cron Job**:
      - Add a line like this (adjust the script name as needed):
          ```bash
          0 3 * * * docker exec docker-media-scripts runscript script-name.py
          ```
          - This example runs the script every day at 3:00 AM.
          - Modify the timing (e.g., `0 3 * * *` for daily at 3:00 AM) as needed.

  3. **Save and Exit**:
      - Save your changes and exit the editor.

  ### Cron References

  If you're struggling with setting cron schedule expressions, a useful tool can be found at [https://crontab.guru](https://crontab.guru/)