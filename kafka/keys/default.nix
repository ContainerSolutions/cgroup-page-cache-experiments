{
  private = builtins.readFile ./id_rsa;
  public = builtins.readFile ./id_rsa.pub;
}
