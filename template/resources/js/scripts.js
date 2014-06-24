$(document).ready(function(){
	$(document.body).delegate('.hierarchy h4', 'click', 
		function(){
			var option = $(this).next().css('display')
			if (option=='block'){
				$(this).next().slideUp(200);
			}
			else{
				$('.hierarchy .dependency, .hierarchy .subclass.first-child').slideUp(200);
				$(this).next().slideDown(200); 
			}
		});
});