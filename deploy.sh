hexo clean && hexo deploy
hexo clean
git add .
git commit -m "$@"
git push -u origin main