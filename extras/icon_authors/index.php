<?

// check for ajax request
if (!empty($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest') {
  file_put_contents('list.json', json_encode($_POST['list'], JSON_PRETTY_PRINT));
  exit();
}

?>
<!doctype html>
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
  .icon-holder {
    border: 1px solid hsl(199,44%,93%);
    background: white;
    box-shadow: 0 2px hsl(210,7%,96%);
    float: left;
    margin: 0 0 14px 14px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    max-width: 200px;
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
    padding: 14px;
  }
  .icon-name {
    margin: 0 0 7px;
    white-space: nowrap;
  }
  input {
    width: 160px;
    font: inherit;
    border: 1px solid #ddd;
    padding: 3px 5px;
  }
  input:focus {
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

<?

# Path to image folder
$imageFolder = '../../public/assets/images/icons/';

# Show only these file types from the image folder
$imageTypes = '{*.svg}';

# Set to true if you prefer sorting images by name
# If set to false, images will be sorted by date
$sortByImageName = true;

# Set to false if you want the oldest images to appear first
# This is only used if images are sorted by date (see above)
$newestImagesFirst = true;

# The rest of the code is technical

# Add images to array
$images = glob($imageFolder . $imageTypes, GLOB_BRACE);

$author_data = json_decode(file_get_contents('list.json'), true);

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

  # Begin adding
?>
  <div class="icon-holder">
    <div class="icon">
      <?= file_get_contents($image) ?>
    </div>
    <div class="icon-body">
      <div class="icon-name"><?= $name ?></div>
      <input class="icon-author" value="<?= $author_data[$filename] ?>" placeholder="Author" data-filename="<?= $filename ?>">
    </div>
  </div>
<? endforeach ?>

<script src="../../app/assets/javascripts/app/lib/core/jquery-2.1.1.min.js"></script>
<script>
  $('input').on('input', storeAuthors)

  function storeAuthors(){
    var iconList = {}

    $('.icon-author').each(function(){
      iconList[$(this).attr('data-filename')] = $(this).val()
    })

    $.post('index.php', { list: iconList }, function(data){ console.log(data) })
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