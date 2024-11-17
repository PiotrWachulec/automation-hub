using 'cdw-automation.bicep'

param env = 'dev'

param spotifyBachata2024PlaylistId = readEnvironmentVariable('SPOTIFY_BACHATA_2024_PLAYLIST_ID')

param spotifyClientId = readEnvironmentVariable('SPOTIFY_CLIENT_ID')

param spotifyClientSecret = readEnvironmentVariable('SPOTIFY_CLIENT_SECRET')

param spotifyRadarPlaylistId =  readEnvironmentVariable('SPOTIFY_RADAR_PLAYLIST_ID')
