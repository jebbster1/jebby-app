import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/cms_page_shell.dart';

class FAQs extends StatefulWidget {
  const FAQs({Key? key}) : super(key: key);

  @override
  State<FAQs> createState() => _FAQsState();
}

class _FAQsState extends State<FAQs> {
  String? role;
  Future getData() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    role = sp.getString('role');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    double res_height = MediaQuery.of(context).size.height;
    return CmsPageShell(
      title: 'FAQs',
      body: CmsPageShell.paddedScroll(
        child: SizedBox(
          width: double.infinity,
          child:
              role == '1'
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      SizedBox(height: res_height * 0.04),
                      Container(
                        child: Text(
                          'Jebby Providers',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),

                      Container(
                        child: Text(
                          "Get the answers you're looking for below. Can't find what you need? Email us at support@jebbylistings.com and we'll be happy to help!",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xff524034),
                          ),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Container(
                        child: Text(
                          'What is Jebby?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Jebby is a rental marketplace where people can list items they own and rent them to others instead of buying. Our platform helps you earn income by renting out your items.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Jebby fits into a group of businesses known as platforms or marketplace businesses. '
                        'Companies like Airbnb, eBay, Turo, and Uber work the same way. They connect customers with providers. '
                        'At Jebby, providers get an account where they can manage the items they list for rent.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'What are Jebby Providers?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Jebby Providers are independent business owners who rent, deliver, set up, and clean items they own. They may be parents, retirees, or small teams building a rental business on Jebby.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Is there a fee to start?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "No. There is no fee to get started.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'How do I create my Jebby Store?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Download the app, create an account, agree to our policies, and start listing items to rent.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Where do I deliver?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "You decide. Most providers deliver within about 5 to 10 miles of where they live, but you set your own range and delivery rates.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'How long does it take to get paid?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "You are paid 24 hours after the rental period begins. It takes approximately 2 business days for the payment to show in your bank account.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'How much money do I make?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "On average, providers earn over \$1,000 per month, though results vary by location, inventory, and availability.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'How will my performance be evaluated?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "We expect reliable, responsive, and professional service from every provider. Renters rate your performance through our rating system.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'What do I get from Jebby when I become a Provider?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "You join a marketplace where renters can find a wide range of items to rent.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Is this my own business?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "As a Jebby Provider, you run your own independent business. You are not a Jebby employee. You agree to follow Jebby guidelines and our Terms of Service.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'How many items can I list?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "As a Jebby Provider, you can list as many items as you want to rent.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Can I set a minimum rental period?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Yes. When you add or edit a listing, you can set a minimum rental period.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'What happens if my item is lost/damaged/stolen?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "If an item is returned late, damaged, or not returned, the renter is responsible for replacement at fair market value. See the Provider Guarantee for details.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.04),
                      Text(
                        'Does Jebby charge any fees?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Jebby charges a service fee for use of the platform. The fee is deducted from each payment before the remaining balance is deposited into your bank account. It applies to rental fees, delivery fees, and damage waiver charges.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Do I need to pay taxes?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Jebby does not collect sales tax for you. Sales tax rules vary by location, and you are responsible for determining, collecting, and remitting any tax that applies.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.04),
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      SizedBox(height: res_height * 0.04),
                      Container(
                        child: Text(
                          'For Renters',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),

                      Container(
                        child: Text(
                          "Get the answers you're looking for below. Can't find what you need? Email us at support@jebbylistings.com and we'll be happy to help!",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xff524034),
                          ),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Container(
                        child: Text(
                          'How far ahead should I make my reservation?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "The sooner, the better. Items are available on a first-come, first-served basis. Demand is usually highest around holidays, winter, and summer.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Can I pay when the reservation starts?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "No. We require full payment at the time of booking. When you book, we hold those items for you and do not offer them to other renters for the same dates, similar to a vacation rental reservation.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'What forms of payment do you accept?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "We accept Visa, MasterCard, American Express, JCB, and Discover. Stripe processes all payments.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'How do you calculate the number of days in a rental?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "We count each day that you have an item as one day.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "For example, if you are planning to rent an item starting early evening on Monday and keep it until the following Monday morning, we would count that as 8 days.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Is there a minimum rental period?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Providers have the option of setting minimum rental periods for each listing. Be sure to check the item description to see if there is a minimum rental period.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Where are items picked up/delivered?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Once you complete your order, your Jebby Provider will contact you to arrange delivery details. Each provider sets their own delivery or pickup terms and any related fees.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'How much does delivery cost?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Each Jebby Provider sets their own delivery rates and service areas. Extra fees may apply for same-day delivery, after-hours delivery, or holiday delivery. Check with the provider or read the item listing for the most accurate delivery cost.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'What is included in the delivery fee?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "The delivery fee includes delivery, setup of most items, and pickup at the completion of a reservation.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'How do I view or modify my Jebby reservation?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "You can log into your Jebby account to view or change your reservation (add items, remove items, extend dates, change dates, update the delivery address, etc.). Changes must be made at least 48 hours before the rental start date. Some changes may require provider approval. If that happens, we will email you when the change is accepted or declined. To change a reservation within 48 hours of the start date, contact the provider by phone, email, or text. The card used for the original booking will be charged for any changes. To use a different card, enter it when you request the change.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Date extensions requested less than 24 hours before the scheduled pickup time may include additional fees.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'What happens if I damage, lose, or return gear in poor condition?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "You are responsible for the gear once it is delivered to you, and it must be returned in the condition it was received. If items are returned damaged or not as they were received, you will be charged additional fees. In the event that an item cannot be fully cleaned or repaired, you will be charged the fair market value to replace the item.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'What is the Jebby service charge?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "To help cover the costs of running Jebby, including processing and customer support, we charge a 10% service fee each time a reservation is made through the platform. The fee is based on the subtotal of rental and delivery charges (before other fees and taxes). The exact amount is shown before you pay and on the cart, delivery, billing, and payment screens.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'What is your cancellation policy?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "You may cancel all or part of your reservation up to 48 hours before the rental start time. Cancellations made more than 48 hours in advance receive a full refund. Cancellations made within 48 hours of the start time are non-refundable.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Can I cancel a reservation myself?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: res_height * 0.02),
                      Text(
                        "Yes. You may log into your Jebby account to cancel your reservation. Once you have successfully logged in, click the “Cancel Order” button.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff524034),
                        ),
                      ),
                      SizedBox(height: res_height * 0.04),
                    ],
                  ),
        ),
      ),
    );
  }
}
