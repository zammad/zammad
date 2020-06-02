<?

$src = '../LICENSE-ICONS-3RD-PARTY.json';

// check for ajax request
if (!empty($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest') {
  return file_put_contents($src, json_encode($_POST['list'], JSON_PRETTY_PRINT));
  exit();
}

?>
<!doctype html>
<meta charset="utf-8">
<title>Zammad Icons</title>
<style>
  html {
    padding: 0 14px 14px 0;
  }
  body {
    margin: 28px 28px 14px 14px;
    background: hsl(210,14%,97%);
    font-family: sans-serif;
    font-size: 13px;
  }
  .controls {
    border: 1px solid hsl(167,72%,60%);
    border-radius: 5px;
    margin: 0 0 28px 14px;
    display: table;
    box-shadow: 0 1px hsl(199,44%,96%);
  }
  .controls label {
    padding: 7px 10px;
    float: left;
    cursor: pointer;
  }
  .controls label:not(:last-child) {
    border-right: 1px solid hsl(167,72%,60%);
  }
  .controls input {
    display: none;
  }
  .controls input:checked + label {
    background: hsl(167,72%,60%);
    color: white;
  }
  .icons {
    display: flex;
    flex-wrap: wrap;
  }
  .icon-holder {
    border: 1px solid hsl(199,44%,93%);
    background: white;
    box-shadow: 0 2px hsl(210,7%,96%);
    margin: 0 0 14px 14px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    flex: 1;
  }
  .icon-holder.is-filtered {
    display: none;
  }
  .icon {
    position: relative;
    padding: 14px;
    width: 100%;
    box-sizing: border-box;
    display: flex;
    justify-content: center;
    background: hsl(210,14%,98%);
  }
  .icon.is-light {
    background: hsl(210,14%,88%);
  }
  .icon svg {
    width: 128px;
    height: 128px;
    position: relative;
  }
  .icon-body {
    padding: 14px 14px 10px;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  .icon-name {
    margin: 0 0 7px;
    white-space: nowrap;
  }
  input:not([type=radio]) {
    margin: 0 0 4px;
    font: inherit;
    border: 1px solid #ddd;
    padding: 3px 5px;
  }
  input:not([type=radio]):focus {
    outline: none;
    border-color: hsl(205,74%,61%);
  }
  /*.icon:before {
    content: "";
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    background-image: 
      linear-gradient(45deg, black 25%, transparent 25%, transparent 75%, black 75%, black), 
      linear-gradient(45deg, black 25%, transparent 25%, transparent 75%, black 75%, black);
    background-size: 20px 20px;
    background-position: 10px 10px, 40px 40px;
    opacity: 0.3;
  }*/
</style>

<div class="controls">
  <input type="radio" value="off" name="filter" id="off"><label for="off">No Filter</label>
  <input type="radio" value="empty_author" name="filter" id="author"><label for="author">No Author</label>
  <input type="radio" value="empty_license" name="filter" id="license"><label for="license">No License</label>
</div>
<div class="icons">
<?

# Path to image folder
$imageFolder = '../public/assets/images/icons/';

# Show only these file types from the image folder
$imageTypes = '{*.svg}';

# Set to true if you prefer sorting images by name
# If set to false, images will be sorted by date
$sortByImageName = true;

# Set to false if you want the oldest images to appear first
# This is only used if images are sorted by date (see above)
$newestImagesFirst = true;

date_default_timezone_set('Europe/Berlin');

# The rest of the code is technical

# Add images to array
$images = glob($imageFolder . $imageTypes, GLOB_BRACE);

$author_data = json_decode(file_get_contents($src), true);

# Sort images
if ($sortByImageName) {
  $sortedImages = $images;
  natsort($sortedImages);
} else {
  # Sort the images based on its 'last modified' time stamp
  $sortedImages = array();
  $count = count($images);
  for ($i = 0; $i < $count; $i++) {
    $sortedImages[date('YmdHis', filemtime($images[$i])) . $i] = $images[$i];
  }
  # Sort images in array
  if ($newestImagesFirst) {
    krsort($sortedImages);
  } else {
    ksort($sortedImages);
  }
}
?>

<? foreach ($sortedImages as $image): ?>
<?
  # Get the name of the image, stripped from image folder path and file type extension
  $filename = basename($image);
  $name = preg_replace('/\\.[^.\\s]{3,4}$/', '', $filename);

  if(!array_key_exists($filename, $author_data)){
    $author_data[$filename] = array(
      'author' => '',
      'url' => '',
      'license' => ''
    );
  }

  # Begin adding
?>
  <div class="icon-holder">
    <div class="icon">
      <?= file_get_contents($image) ?>
    </div>
    <form class="icon-body" data-filename="<?= $filename ?>">
      <div class="icon-name"><?= $name ?></div>
      <input name="author" value="<?= $author_data[$filename]['author'] ?>" placeholder="Author">
      <input type="url" name="url" value="<?= $author_data[$filename]['url'] ?>" placeholder="URL">
      <input name="license" value="<?= $author_data[$filename]['license'] ?>" placeholder="License">
    </form>
  </div>
<? endforeach ?>
</div>

<script src="../app/assets/javascripts/app/lib/core/jquery-2.2.1.js"></script>
<script>
  var self = "<?= basename($_SERVER["SCRIPT_FILENAME"]) ?>"
  var filter = "off"
  var filterTimeout

  if(localStorage.getItem('icon-list-filter')){
    filter = localStorage.getItem('icon-list-filter')
    applyFilter()
  }
  
  $('[name="filter"][value="'+ filter +'"]').prop('checked', true)

  $('input').on('input', storeAuthors)

  function storeAuthors(){
    var iconList = {}

    $('.icon-holder form').each(function(){
      iconList[$(this).attr('data-filename')] = {
        author: this.elements.author.value,
        url: this.elements.url.value,
        license: this.elements.license.value
      }
    })

    $.post(self, { list: iconList }, function(data){ console.log(data) })
  }

  $('[name="filter"]').change(function(){
    filter = this.value
    localStorage.setItem('icon-list-filter', filter)
    applyFilter()
  })

  function applyFilter(){
    $('.icon-holder').removeClass('is-filtered').each(function(){
      var holder = $(this)

      switch(filter){
        case "empty_author":
          if(holder.find("[name='author']").val())
            holder.addClass('is-filtered')
          break;
        case "empty_license":
          if(holder.find("[name='license']").val())
            holder.addClass('is-filtered')
          break;
      }
    });
  }

  $('svg').each(function(i, svg){
    var areas = []
    var svgBoundingBox = svg.getBoundingClientRect()
    var svgArea = svgBoundingBox.width * svgBoundingBox.height

    $(svg).find('*').each(function(i, el){
      var fill = $(el).attr('fill')
      if(fill && fill != 'none'){
        var childBoundingBox = el.getBoundingClientRect()
        areas.push({
          luminance: getLuminance(fill),
          areaPercentage: (childBoundingBox.width * childBoundingBox.height)/svgArea
        })
      }
    })

    if(!areas.length)
      return

    var averageLuminance = areas.reduce(function(previousValue, currentValue, index, array){
      if(array.length == 1)
        return currentValue.luminance
      else
        return previousValue + currentValue.luminance * currentValue.areaPercentage
    }, 0)
    
    if(averageLuminance > 220){
      $(svg).parent().addClass('is-light')
    }
  })

  //
  // from http://stackoverflow.com/questions/12043187/how-to-check-if-hex-color-is-too-black
  //
  function getLuminance(hex){
    var c = hex.substring(1);      // strip #
    var rgb = parseInt(c, 16);   // convert rrggbb to decimal
    var r = (rgb >> 16) & 0xff;  // extract red
    var g = (rgb >>  8) & 0xff;  // extract green
    var b = (rgb >>  0) & 0xff;  // extract blue

    return 0.2126 * r + 0.7152 * g + 0.0722 * b; // per ITU-R BT.709
  }
</script>