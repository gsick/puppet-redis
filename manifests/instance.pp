
define redis::instance(
  $servername = $name, 
  $conf, 
  $sentinel = false,
) {

 notice("${servername}")
notice("${conf}")
notice("${sentinel}")

}