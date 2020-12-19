Este es un modulo de terraform que permite realizar la creación de un repositorio ECR en AWS a traves de codigo, este modulo contiene los siguientes archivos:
main.tf: Este archivo almacena la configuracion principal a desplegar, encuentra previamente configurado a traves de variables las cuales estan definidas en el archivo variables.
provider.tf: Este archivo se encuentra configurado para que solo permita acceso a AWS a traves de un rol, ya que por politicas de seguridad no es una buena practica el almacenaje de secrets key en el codigo. 
outputs.tf: Este archivo permite el almacenaje de los outpus generados en cada modulo, de forma que puedan ser almacenados para ser reutilizados en la creación de un nuevo modulo de ser necesario.
variables.tf: Este archivo permite almacenar y parametrizar las variables que serán usadas en los modulos a desplegar.
version.tf: Este archivo guarda la configuracion de las versiones que son usadas en las aplicaciones de los modulos. 